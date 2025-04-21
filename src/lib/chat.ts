import { Message, ChatSession } from '../types';
import { supabase } from './supabase';
import { OpenAIClient } from './openai';
import { TheBrainAPI, getUserThoughtId } from './thebrain';

async function fetchMessageHistory(sessionId: string): Promise<Message[]> {
  try {
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .eq('session_id', sessionId)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Error fetching message history:', error);
      return [];
    }

    return data || [];
  } catch (error) {
    console.error('Error in fetchMessageHistory:', error);
    return [];
  }
}

async function handleToolCalls(
  toolCalls: any[],
  theBrain: TheBrainAPI,
  openai: OpenAIClient,
  chatSession: ChatSession,
  onUpdate: (messages: Message[]) => void
) {
  const toolResults = [];
  
  for (const toolCall of toolCalls) {
    if (toolCall.type === 'function') {
      const args = JSON.parse(toolCall.function.arguments);
      const result = await theBrain[toolCall.function.name](args);

      toolResults.push({
        name: toolCall.function.name,
        result,
        tool_call_id: toolCall.id
      });

      // Ensure tool result content is always a string
      const toolContent = typeof result === 'string' ? result : JSON.stringify(result);
      
      // Store tool result as a tool message
      await supabase
        .from('messages')
        .insert({
          session_id: chatSession.id,
          content: toolContent,
          role: 'tool',
          tool_call_id: toolCall.id,
          name: toolCall.function.name
        });

      // Update UI with latest messages
      const messages = await fetchMessageHistory(chatSession.id);
      onUpdate(messages);
    }
  }

  // Fetch updated message history before processing tool results
  const currentMessages = await fetchMessageHistory(chatSession.id);
  
  const processedResponse = await openai.processToolResults(currentMessages, toolResults);

  // Ensure content is always a string before inserting
  const responseContent = processedResponse.content ? String(processedResponse.content).trim() : '';
  
  if (responseContent || processedResponse.tool_calls) {
    await supabase
      .from('messages')
      .insert({
        session_id: chatSession.id,
        content: responseContent,
        role: 'assistant',
        tool_call_id: null,
        tool_calls: processedResponse.tool_calls
      });

    // Update UI with latest messages
    const messages = await fetchMessageHistory(chatSession.id);
    onUpdate(messages);
  }

  if (processedResponse.tool_calls?.length) {
    return handleToolCalls(
      processedResponse.tool_calls,
      theBrain,
      openai,
      chatSession,
      onUpdate
    );
  }

  return processedResponse;
}

export async function sendMessage({
  input,
  chatSession,
  theBrainApiKey,
  brainId,
  openAIKey,
  onUpdate,
}: {
  input: string;
  chatSession: ChatSession;
  theBrainApiKey: string;
  brainId: string;
  openAIKey: string;
  onUpdate: (messages: Message[]) => void;
}) {
  try {
    // Get user's thought ID from settings
    const userThoughtId = await getUserThoughtId();

    // Save user message to database
    await supabase
      .from('messages')
      .insert({
        session_id: chatSession.id,
        content: input.trim(),
        role: 'user',
      });

    // Update UI with user message and ensure we have a valid array
    const messagesAfterUser = await fetchMessageHistory(chatSession.id);
    onUpdate(messagesAfterUser);

    const theBrain = new TheBrainAPI(theBrainApiKey, brainId);
    const openai = new OpenAIClient(openAIKey, userThoughtId, theBrain);

    const initialResponse = await openai.chat(messagesAfterUser);
    
    // Ensure content is always a string before inserting
    const responseContent = initialResponse.content ? String(initialResponse.content).trim() : '';
    
    // Save assistant message to database
    await supabase
      .from('messages')
      .insert({
        session_id: chatSession.id,
        content: responseContent,
        role: 'assistant',
        tool_call_id: null,
        tool_calls: initialResponse.tool_calls
      });

    // Update UI with assistant message
    const messagesAfterAssistant = await fetchMessageHistory(chatSession.id);
    onUpdate(messagesAfterAssistant);

    if (initialResponse.tool_calls) {
      return handleToolCalls(
        initialResponse.tool_calls,
        theBrain,
        openai,
        chatSession,
        onUpdate
      );
    }

    return initialResponse;
  } catch (error) {
    console.error('Error in sendMessage:', error);
    throw error;
  }
}