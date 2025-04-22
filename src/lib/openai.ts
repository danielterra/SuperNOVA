import OpenAI from 'openai';
import { Message } from '../types';
import { getTools } from './thebrain';
import { encode } from 'gpt-tokenizer';
import { supabase } from './supabase';

const getSystemPrompt = async (theBrain: any, userThoughtId: string | null) => {
  // Get available thought types if we have a theBrain instance
  let availableTypes = '';
  if (theBrain) {
    try {
      const types = await theBrain.request(`/thoughts/${theBrain.brainId}/types`);
      if (types && types.length > 0) {
        availableTypes = `\nAvailable Thought Types in your brain:`;
        types.forEach((type: any) => {
          availableTypes += `\n- ${type.name} (ID: ${type.id})${type.description ? `: ${type.description}` : ''}`;
        });
      }
    } catch (error) {
      console.error('Error loading thought types:', error);
      availableTypes = '\nNote: Unable to load available thought types at the moment.';
    }
  }

  const basePrompt = `You are SuperNOVA, an AI assistant with access to the user's personal knowledge base in TheBrain. You can search for information in TheBrain to help answer questions and store information in the graph.

When working with thoughts in TheBrain, you have access to several thought kinds:

1. Normal Thoughts (kind=1):
   - Represent specific instances, concrete information
   - Example: A specific project, person, city, etc

2. Type Thoughts (kind=2):
   - Define abstract concepts
   - Example: "Project", "Person", "Role"
   ${availableTypes}

3. Tag Thoughts (kind=4):
   - Used for state
   - Example: "Alive", "Dead", "In Progress", "Done", "Removed"

When creating new thoughts:
1. For specift entities and concepts:
   - Use Normal thoughts (kind=1)
   - Set appropriate type from the available thought types above

2. For events and meetings:
   - Use Event thoughts (kind=3)
   - Include date/time information in the name or notes
   - Link to relevant participants and topics

3. For relationships:
   - Child (relation=1): Represents hierarchical "part of" relationships
   - Parent (relation=2): Represents "contains" or "owns" relationships
   - Jump (relation=3): Represents non-hierarchical associations
   - Sibling (relation=4): Represents peer or related items

CRITICAL: When creating or linking thoughts:
1. ALWAYS use appropriate thought types based on the content
2. ALWAYS establish meaningful relationships between thoughts
3. NEVER create orphaned thoughts - always connect to relevant context
4. PREFER using existing types over creating new ones
5. MAINTAIN consistent naming conventions within each type`;

  // If no user thought ID, add instructions for user identification
  if (!userThoughtId) {
    return `${basePrompt}

IMPORTANT: I notice that I don't have your identity set up in TheBrain yet. Before we continue, I need to know your name so I can create or find your identity in the system.

Please tell me your name, and I'll:
1. Search for an existing thought representing you
2. If not found, create a new Person thought with your name
3. Establish appropriate connections to relevant contexts

You can simply respond with your name or "My name is [Your Name]".`;
  }

  // If we have a user thought ID, include user context
  let userContext = '';
  if (userThoughtId && theBrain) {
    try {
      const graph = await theBrain.getThoughtGraph({ thoughtId: userThoughtId });
      const thought = graph.activeThought;
      
      userContext = `\nI recognize you as ${thought.name} (ID: ${userThoughtId}). Here's your context:
- Type: ${thought.typeName || 'Not specified'}
- Connected to ${graph.parents.length} parent thoughts
- Has ${graph.children.length} child thoughts
- Linked to ${graph.jumps.length} related thoughts

I'll use this context to provide personalized responses and maintain relevant connections in your knowledge graph.`;
    } catch (error) {
      console.error('Error fetching user context:', error);
      userContext = `\nI recognize you by ID ${userThoughtId}, but I'm having trouble accessing your complete context right now.`;
    }
  }

  // Instructions for task reminders based on SuperNOVA objectives
  let tasksSection = '';
  if (theBrain) {
    try {
      // Find the SuperNOVA objective thought
      const superNovaSearch = await theBrain.searchThoughts({ query: 'SuperNOVA', maxResults: 1 });
      if (superNovaSearch.length > 0) {
        const superNovaId = superNovaSearch[0].id;
        const snGraph = await theBrain.getThoughtGraph({ thoughtId: superNovaId });
        const tasks = snGraph.children;
        if (tasks && tasks.length > 0) {
          // Current date in dd/MM/yyyy
          const now = new Date();
          const todayStr = `${now.getDate().toString().padStart(2,'0')}/${(now.getMonth()+1).toString().padStart(2,'0')}/${now.getFullYear()}`;
          tasksSection = `\n\nCurrent Date: ${todayStr}\nYour Objectives:\n`;
          tasks.forEach((task: any) => {
            tasksSection += `- ${task.name}\n`;
          });
        }
      }
    } catch (err) {
      console.error('Error fetching SuperNOVA objectives:', err);
    }
  }
  const searchInstructions = `
When searching and analyzing information:

1. Start with focused searches:
   - Use searchThoughts to find directly relevant content
   - Prioritize Normal thoughts connected to your context
   - Consider thought types for better context

2. Analyze connections for each relevant thought:
   - Use getThoughtGraph to understand relationships
   - Look for patterns in parent/child hierarchies
   - Identify meaningful links between thoughts
   - Consider the type and role of each connected thought

3. Gather detailed content:
   - Use getNotes to get full thought content
   - Check notes of directly connected thoughts
   - Look for patterns and relationships in the content

4. When creating new thoughts:
   - Always use appropriate thought types from the available list
   - Establish meaningful relationships
   - Connect to relevant existing thoughts
   - Maintain consistent naming within types
   - AVOID composed tought names, create small thoghts and link them

5. When providing responses:
   - Focus on specific, relevant information
   - Consider the context from related thoughts
   - Explain relationships and connections
   - Suggest relevant actions or next steps`;

  return `${basePrompt}${userContext}${tasksSection}${searchInstructions}`;
};

const MAX_TOKENS = 128000;
const TRUNCATION_MESSAGE = {
  role: 'system' as const,
  content: '[Note: Some earlier messages were summarized to stay within token limits]'
};

export class OpenAIClient {
  private client: OpenAI;
  private userThoughtId: string | null;
  private theBrain: any;

  constructor(apiKey: string, userThoughtId: string | null = null, theBrain: any = null) {
    this.client = new OpenAI({
      apiKey,
      dangerouslyAllowBrowser: true
    });
    this.userThoughtId = userThoughtId;
    this.theBrain = theBrain;
  }

  private countTokens(messages: any[]): number {
    let totalTokens = 0;
    for (const message of messages) {
      // Count tokens in the message content
      totalTokens += encode(message.content || '').length;
      
      // Add tokens for message metadata
      totalTokens += 4; // Role and other metadata

      // Count tokens in tool calls if present
      if (message.tool_calls) {
        for (const tool of message.tool_calls) {
          totalTokens += encode(tool.function.name).length;
          totalTokens += encode(tool.function.arguments).length;
          totalTokens += 4; // Tool call metadata
        }
      }
    }
    return totalTokens;
  }

  private truncateMessages(messages: any[]): any[] {
    const systemMessage = messages[0];
    let truncatedMessages = [systemMessage];
    let currentTokens = this.countTokens([systemMessage]);
    
    // Start from the most recent message
    const recentMessages = messages.slice(1).reverse();
    
    for (const message of recentMessages) {
      const messageTokens = this.countTokens([message]);
      if (currentTokens + messageTokens <= MAX_TOKENS) {
        truncatedMessages.push(message);
        currentTokens += messageTokens;
      } else {
        break;
      }
    }
    
    // If we truncated messages, add the truncation notice
    if (truncatedMessages.length < messages.length) {
      truncatedMessages = [systemMessage, TRUNCATION_MESSAGE, ...truncatedMessages.slice(1)];
    }
    
    return truncatedMessages.reverse();
  }

  async chat(messages: Message[], useTools = true) {
    const systemPrompt = await getSystemPrompt(this.theBrain, this.userThoughtId);
    
    const messagesWithContext = [
      { role: 'system', content: systemPrompt },
      ...messages.map(msg => ({
        role: msg.role as 'user' | 'assistant' | 'system' | 'tool',
        content: msg.content,
        tool_call_id: msg.tool_call_id,
        tool_calls: msg.tool_calls,
        name: msg.role === 'tool' ? msg.name : undefined
      }))
    ];

    const truncatedMessages = this.truncateMessages(messagesWithContext);

    const completion = await this.client.chat.completions.create({
      model: 'gpt-4o',
      messages: truncatedMessages,
      temperature: 0.7,
      max_tokens: 16384,
      top_p: 0.9,
      frequency_penalty: 0.5,
      presence_penalty: 0.5,
      ...(useTools ? { 
        tools: getTools(!!this.userThoughtId),
        tool_choice: 'auto'
      } : {})
    });

    const response = completion.choices[0].message;
    
    if (!response) {
      throw new Error('No response from OpenAI');
    }

    return response;
  }

  async processToolResults(messages: Message[], toolResults: any[]) {
    // Create a map of tool_call_ids from assistant messages
    const validToolCallIds = new Set<string>();
    messages.forEach(msg => {
      if (msg.role === 'assistant' && msg.tool_calls) {
        msg.tool_calls.forEach(tc => {
          if (tc && tc.id) {
            validToolCallIds.add(tc.id);
          }
        });
      }
    });

    // Filter out existing tool messages that don't have a matching tool_call_id
    const validMessages = messages.filter(msg => {
      if (msg.role !== 'tool') return true;
      return msg.tool_call_id && validToolCallIds.has(msg.tool_call_id);
    });

    // Filter out tool results that already have a corresponding tool message
    const existingToolCallIds = new Set(
      validMessages
        .filter(msg => msg.role === 'tool' && msg.tool_call_id)
        .map(msg => msg.tool_call_id)
    );

    const newToolMessages = (toolResults || [])
      .filter(result => result && result.tool_call_id && !existingToolCallIds.has(result.tool_call_id))
      .map(result => ({
        role: 'tool' as const,
        name: result.name,
        content: JSON.stringify(result.result),
        tool_call_id: result.tool_call_id
      }));

    const messagesWithToolResults = [
      ...validMessages,
      ...newToolMessages
    ];

    // Get updated system prompt with latest user context
    const systemPrompt = await getSystemPrompt(this.theBrain, this.userThoughtId);

    // Truncate messages before sending to OpenAI
    const truncatedMessages = this.truncateMessages([
      { role: 'system', content: systemPrompt },
      ...messagesWithToolResults.map(msg => ({
        role: msg.role as 'user' | 'assistant' | 'system' | 'tool',
        content: msg.content,
        tool_call_id: msg.tool_call_id,
        tool_calls: msg.tool_calls,
        name: msg.role === 'tool' ? msg.name : undefined
      }))
    ]);

    const completion = await this.client.chat.completions.create({
      model: 'gpt-4o',
      messages: truncatedMessages,
      temperature: 0.7,
      max_tokens: 16384,
      top_p: 0.9,
      frequency_penalty: 0.5,
      presence_penalty: 0.5,
      tools: getTools(!!this.userThoughtId),
      tool_choice: 'auto'
    });

    const response = completion.choices[0].message;
    
    if (!response) {
      throw new Error('No response from OpenAI');
    }

    // If there are more tool calls, we need to continue the process
    if (response.tool_calls?.length) {
      return {
        ...response,
        content: response.content || "I'm analyzing the connections between these thoughts...",
      };
    }

    return response;
  }
}
// Functions to get and save OpenAI API key in Supabase
export async function getOpenAIKey(): Promise<string | null> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('User not authenticated');
  const { data, error } = await supabase
    .from('user_settings')
    .select('openai_api_key')
    .eq('user_id', user.id)
    .single();
  if (error) throw error;
  return data?.openai_api_key || null;
}

export async function saveOpenAIKey(key: string): Promise<void> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('User not authenticated');
  const { error } = await supabase
    .from('user_settings')
    .upsert({
      user_id: user.id,
      openai_api_key: key,
      updated_at: new Date().toISOString()
    }, { onConflict: 'user_id' });
  if (error) throw error;
}