import { Brain, TheBrainThought, TheBrainLink, ThoughtType } from '../types';
import { supabase } from './supabase';

// Store brain types in memory
let brainTypes: Map<string, ThoughtType> = new Map();

export async function getBrains(apiKey: string): Promise<Brain[]> {
  const response = await fetch('https://api.bra.in/brains', {
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Accept': 'application/json'
    }
  });

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('Invalid API key');
    } else if (response.status === 403) {
      throw new Error('Access denied');
    }
    throw new Error(`Failed to fetch brains: ${response.statusText}`);
  }

  const brains = await response.json();
  
  if (!brains || brains.length === 0) {
    throw new Error('No brains found in your TheBrain account. Please create a brain first.');
  }

  return brains;
}

export async function getBrainId(): Promise<string | null> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { data, error } = await supabase
      .from('user_settings')
      .select('brain_id')
      .eq('user_id', user.id)
      .single();

    if (error) throw error;
    return data?.brain_id || null;
  } catch (error) {
    console.error('Error getting brain ID:', error);
    throw error;
  }
}

export async function getUserThoughtId(): Promise<string | null> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { data, error } = await supabase
      .from('user_settings')
      .select('thought_id')
      .eq('user_id', user.id)
      .single();

    if (error) throw error;
    return data?.thought_id || null;
  } catch (error) {
    console.error('Error getting user thought ID:', error);
    return null;
  }
}

export async function saveBrainId(brainId: string): Promise<void> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('user_settings')
      .upsert({ 
        user_id: user.id,
        brain_id: brainId,
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'user_id'
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error saving brain ID:', error);
    throw error;
  }
}

export async function saveTheBrainApiKey(apiKey: string): Promise<void> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('user_settings')
      .upsert({ 
        user_id: user.id,
        thebrain_api_key: apiKey,
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'user_id'
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error saving API key:', error);
    throw error;
  }
}

export async function saveUserThoughtId(thoughtId: string): Promise<void> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { error } = await supabase
      .from('user_settings')
      .upsert({ 
        user_id: user.id,
        thought_id: thoughtId,
        updated_at: new Date().toISOString()
      }, {
        onConflict: 'user_id'
      });

    if (error) throw error;
  } catch (error) {
    console.error('Error saving user thought ID:', error);
    throw error;
  }
}

export async function getTheBrainApiKey(): Promise<string | null> {
  try {
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) throw new Error('User not authenticated');

    const { data, error } = await supabase
      .from('user_settings')
      .select('thebrain_api_key')
      .eq('user_id', user.id)
      .single();

    if (error) throw error;
    return data?.thebrain_api_key || null;
  } catch (error) {
    console.error('Error getting API key:', error);
    throw error;
  }
}

// Core tools that are always available
const coreTools = [
  {
    type: 'function',
    function: {
      name: 'searchThoughts',
      description: 'Search for thoughts in TheBrain',
      parameters: {
        type: 'object',
        properties: {
          query: {
            type: 'string',
            description: 'The search query'
          },
          maxResults: {
            type: 'number',
            description: 'Maximum number of results to return',
            default: 30
          }
        },
        required: ['query']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'getThoughtGraph',
      description: 'Get the complete graph of connections for a thought, including parent/child relationships and links',
      parameters: {
        type: 'object',
        properties: {
          thoughtId: {
            type: 'string',
            description: 'ID of the thought'
          }
        },
        required: ['thoughtId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'getNotes',
      description: 'Get the detailed notes content of a thought',
      parameters: {
        type: 'object',
        properties: {
          thoughtId: {
            type: 'string',
            description: 'ID of the thought'
          }
        },
        required: ['thoughtId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'createThought',
      description: 'Create a new thought in TheBrain',
      parameters: {
        type: 'object',
        properties: {
          name: {
            type: 'string',
            description: 'The name of the thought'
          },
          label: {
            type: 'string',
            description: 'Optional label for the thought'
          },
          sourceThoughtId: {
            type: 'string',
            description: 'ID of the source thought to connect to'
          },
          relation: {
            type: 'number',
            description: 'Relationship type: 1=Child, 2=Parent, 3=Jump, 4=Sibling',
            enum: [1, 2, 3, 4]
          },
          kind: {
            type: 'number',
            description: 'Kind of thought: 1=Normal, 2=Type, 3=Event, 4=Tag, 5=System',
            enum: [1, 2, 3, 4, 5],
            default: 1
          },
          acType: {
            type: 'number',
            description: 'Access type: 0=Public, 1=Private',
            enum: [0, 1],
            default: 0
          },
          typeId: {
            type: 'string',
            description: 'Optional ID of the thought type'
          }
        },
        required: ['name', 'sourceThoughtId', 'relation']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'createLink',
      description: 'Create a link between two thoughts in TheBrain',
      parameters: {
        type: 'object',
        properties: {
          thoughtIdA: {
            type: 'string',
            description: 'ID of the source thought'
          },
          thoughtIdB: {
            type: 'string',
            description: 'ID of the target thought'
          },
          relation: {
            type: 'number',
            description: 'Relationship type: 1=Child, 2=Parent, 3=Jump, 4=Sibling',
            enum: [1, 2, 3, 4]
          },
          name: {
            type: 'string',
            description: 'Optional label for the link'
          }
        },
        required: ['thoughtIdA', 'thoughtIdB', 'relation']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'getLink',
      description: 'Get details about a link between two thoughts',
      parameters: {
        type: 'object',
        properties: {
          thoughtIdA: {
            type: 'string',
            description: 'ID of the first thought'
          },
          thoughtIdB: {
            type: 'string',
            description: 'ID of the second thought'
          }
        },
        required: ['thoughtIdA', 'thoughtIdB']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'getLinkDetails',
      description: 'Get detailed information about a specific link',
      parameters: {
        type: 'object',
        properties: {
          linkId: {
            type: 'string',
            description: 'ID of the link'
          }
        },
        required: ['linkId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'updateLink',
      description: 'Update properties of an existing link',
      parameters: {
        type: 'object',
        properties: {
          linkId: {
            type: 'string',
            description: 'ID of the link to update'
          },
          name: {
            type: 'string',
            description: 'New label for the link'
          },
          relation: {
            type: 'number',
            description: 'New relationship type: 1=Child, 2=Parent, 3=Jump, 4=Sibling',
            enum: [1, 2, 3, 4]
          },
          color: {
            type: 'string',
            description: 'RGB hexadecimal color for the link (e.g., "#ff7145")'
          },
          thickness: {
            type: 'number',
            description: 'Thickness of the link'
          }
        },
        required: ['linkId']
      }
    }
  },
  {
    type: 'function',
    function: {
      name: 'deleteLink',
      description: 'Delete a link between thoughts',
      parameters: {
        type: 'object',
        properties: {
          linkId: {
            type: 'string',
            description: 'ID of the link to delete'
          }
        },
        required: ['linkId']
      }
    }
  }
];

// Export tools based on whether we have a user thought ID
export const getTools = (hasUserThought: boolean) => {
  return hasUserThought ? coreTools : [...coreTools];
};

interface SimplifiedThought {
  id: string;
  name: string;
  kind: number;
  label?: string;
  typeId?: string;
  typeName?: string;
}

interface SimplifiedLink {
  id: string;
  thoughtIdA: string;
  thoughtIdB: string;
  name?: string;
  direction: number;
  relation: number;
  color?: string;
  thickness?: number;
  kind?: number;
  meaning?: number;
  typeId?: string;
  creationDateTime?: string;
  modificationDateTime?: string;
}

interface SimplifiedGraph {
  activeThought: SimplifiedThought;
  parents: SimplifiedThought[];
  children: SimplifiedThought[];
  jumps: SimplifiedThought[];
  links: SimplifiedLink[];
}

export class TheBrainAPI {
  private apiKey: string;
  private brainId: string;

  constructor(apiKey: string, brainId: string) {
    this.apiKey = apiKey;
    this.brainId = brainId;
    this.loadTypes();
  }

  private async request(endpoint: string, options: RequestInit = {}) {
    if (!this.brainId) {
      throw new Error('No Brain ID selected. Please select a brain in settings.');
    }

    const url = `https://api.bra.in${endpoint}`;
    const response = await fetch(url, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...options.headers,
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`TheBrain API error (${response.status}): ${errorText || response.statusText}`);
    }

    return response.json();
  }

  private async loadTypes() {
    try {
      const response = await this.request(`/thoughts/${this.brainId}/types`);
      brainTypes = new Map(response.map((type: ThoughtType) => [type.id, type]));
    } catch (error) {
      console.error('Error loading brain types:', error);
    }
  }

  private enrichThoughtWithType(thought: SimplifiedThought): SimplifiedThought {
    if (thought.typeId && brainTypes.has(thought.typeId)) {
      return {
        ...thought,
        typeName: brainTypes.get(thought.typeId)?.name
      };
    }
    return thought;
  }

  async searchThoughts({ query, maxResults = 30 }: { query: string; maxResults?: number }) {
    try {
      const response = await this.request(`/search/${this.brainId}?queryText=${encodeURIComponent(query)}&maxResults=${maxResults}&onlySearchThoughtNames=false`);
      
      // Log the raw response for debugging
      console.log('Search response:', response);

      // The response is an array of search results
      if (!Array.isArray(response)) {
        console.warn('Invalid search response format:', response);
        return [];
      }
      
      // Filter for thought results (searchResultType === 1) and map to our format
      const thoughts = response
        .filter(result => result.searchResultType === 1 && result.sourceThought)
        .map(result => {
          const thought = result.sourceThought;
          return this.enrichThoughtWithType({
            id: thought.id,
            name: thought.name,
            kind: thought.kind,
            label: thought.label,
            typeId: thought.typeId
          });
        });

      // Log the processed thoughts for debugging
      console.log('Processed thoughts:', thoughts);
      
      return thoughts;
    } catch (error) {
      console.error('Error in searchThoughts:', error);
      throw error;
    }
  }

  async createThought({ 
    name, 
    label, 
    sourceThoughtId, 
    relation, 
    kind = 1, 
    acType = 0,
    typeId 
  }: { 
    name: string;
    label?: string;
    sourceThoughtId: string;
    relation: number;
    kind?: number;
    acType?: number;
    typeId?: string;
  }): Promise<SimplifiedThought> {
    const thoughtData = {
      name,
      label,
      sourceThoughtId,
      relation,
      kind,
      acType,
      typeId
    };

    const response = await this.request(`/thoughts/${this.brainId}`, {
      method: 'POST',
      body: JSON.stringify(thoughtData)
    });

    return this.enrichThoughtWithType({
      id: response.id,
      name: response.name,
      kind: response.kind,
      label: response.label,
      typeId: response.typeId
    });
  }

  async createLink({ 
    thoughtIdA, 
    thoughtIdB, 
    relation, 
    name 
  }: { 
    thoughtIdA: string;
    thoughtIdB: string;
    relation: number;
    name?: string;
  }): Promise<string> {
    const linkData = {
      thoughtIdA,
      thoughtIdB,
      relation,
      name
    };

    const response = await this.request(`/links/${this.brainId}`, {
      method: 'POST',
      body: JSON.stringify(linkData)
    });

    return response.id;
  }

  async getLink({ 
    thoughtIdA, 
    thoughtIdB 
  }: { 
    thoughtIdA: string;
    thoughtIdB: string;
  }): Promise<SimplifiedLink | null> {
    try {
      const response = await this.request(`/links/${this.brainId}/${thoughtIdA}/${thoughtIdB}`);
      return {
        id: response.id,
        thoughtIdA: response.thoughtIdA,
        thoughtIdB: response.thoughtIdB,
        name: response.name,
        direction: response.direction,
        relation: response.relation,
        color: response.color,
        thickness: response.thickness,
        kind: response.kind,
        meaning: response.meaning,
        typeId: response.typeId,
        creationDateTime: response.creationDateTime,
        modificationDateTime: response.modificationDateTime
      };
    } catch (error) {
      if (error instanceof Error && error.message.includes('404')) {
        return null;
      }
      throw error;
    }
  }

  async getLinkDetails({ 
    linkId 
  }: { 
    linkId: string;
  }): Promise<SimplifiedLink> {
    const response = await this.request(`/links/${this.brainId}/${linkId}`);
    return {
      id: response.id,
      thoughtIdA: response.thoughtIdA,
      thoughtIdB: response.thoughtIdB,
      name: response.name,
      direction: response.direction,
      relation: response.relation,
      color: response.color,
      thickness: response.thickness,
      kind: response.kind,
      meaning: response.meaning,
      typeId: response.typeId,
      creationDateTime: response.creationDateTime,
      modificationDateTime: response.modificationDateTime
    };
  }

  async updateLink({ 
    linkId,
    name,
    relation,
    color,
    thickness
  }: { 
    linkId: string;
    name?: string;
    relation?: number;
    color?: string;
    thickness?: number;
  }): Promise<void> {
    const patchDocument = [];
    
    if (name !== undefined) {
      patchDocument.push({
        op: 'replace',
        path: '/name',
        value: name
      });
    }
    
    if (relation !== undefined) {
      patchDocument.push({
        op: 'replace',
        path: '/relation',
        value: relation
      });
    }
    
    if (color !== undefined) {
      patchDocument.push({
        op: color ? 'replace' : 'remove',
        path: '/color',
        value: color || null
      });
    }
    
    if (thickness !== undefined) {
      patchDocument.push({
        op: 'replace',
        path: '/thickness',
        value: thickness
      });
    }

    if (patchDocument.length > 0) {
      await this.request(`/links/${this.brainId}/${linkId}`, {
        method: 'PATCH',
        body: JSON.stringify({ patchDocument })
      });
    }
  }

  async deleteLink({ 
    linkId 
  }: { 
    linkId: string;
  }): Promise<void> {
    await this.request(`/links/${this.brainId}/${linkId}`, {
      method: 'DELETE'
    });
  }

  async getThoughtGraph({ thoughtId }: { thoughtId: string }): Promise<SimplifiedGraph> {
    const response = await this.request(`/thoughts/${this.brainId}/${thoughtId}/graph`);
    
    const simplifyThought = (thought: any): SimplifiedThought => 
      this.enrichThoughtWithType({
        id: thought.id,
        name: thought.name,
        kind: thought.kind,
        label: thought.label,
        typeId: thought.typeId
      });

    const simplifyLink = (link: any): SimplifiedLink => ({
      id: link.id,
      thoughtIdA: link.thoughtIdA,
      thoughtIdB: link.thoughtIdB,
      name: link.name,
      direction: link.direction,
      relation: link.relation
    });

    return {
      activeThought: simplifyThought(response.activeThought),
      parents: (response.parents || []).map(simplifyThought),
      children: (response.children || []).map(simplifyThought),
      jumps: (response.jumps || []).map(simplifyThought),
      links: (response.links || []).map(simplifyLink)
    };
  }

  async getNotes({ thoughtId }: { thoughtId: string }) {
    return this.request(`/notes/${this.brainId}/${thoughtId}`);
  }

  async findOrCreateUserThought(name: string): Promise<string> {
    // First, try to find an existing thought with the given name
    const searchResults = await this.searchThoughts({ query: name, maxResults: 1 });
    
    let thoughtId: string;
    
    if (searchResults.length > 0) {
      thoughtId = searchResults[0].id;
    } else {
      // If no thought found, create a new one
      const personTypeId = Array.from(brainTypes.values())
        .find(type => type.name.toLowerCase() === 'person')?.id;

      const newThought = await this.createThought({ 
        name,
        kind: 1, // Normal thought
        typeId: personTypeId,
        sourceThoughtId: '0', // Root level
        relation: 1 // Child
      });
      thoughtId = newThought.id;
    }

    // Save the thought ID
    await saveUserThoughtId(thoughtId);
    
    return thoughtId;
  }

  async saveUserThoughtId({ thoughtId }: { thoughtId: string }): Promise<void> {
    await saveUserThoughtId(thoughtId);
  }
}