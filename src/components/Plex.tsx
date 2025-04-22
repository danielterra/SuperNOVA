import React, { useEffect, useLayoutEffect, useState, useMemo, useRef } from 'react';
import { TheBrainAPI } from '../lib/thebrain';

interface PlexProps {
  apiKey: string | null;
  brainId: string | null;
  thoughtId: string | null;
  onSelect?: (thoughtId: string) => void;
}

// Simplified types for graph nodes and links
interface ThoughtNode {
  id: string;
  name: string;
  typeName?: string;
}

interface LinkNode {
  id: string;
  thoughtIdA: string;
  thoughtIdB: string;
  name?: string;
  relation?: number;
}

interface Graph {
  activeThought: ThoughtNode;
  parents: ThoughtNode[];
  children: ThoughtNode[];
  jumps: ThoughtNode[];
  links: LinkNode[];
}

export const Plex: React.FC<PlexProps> = ({ apiKey, brainId, thoughtId, onSelect }) => {
  // Core state
  const [graph, setGraph] = useState<Graph | null>(null);
  const [error, setError] = useState<string | null>(null);
  // Refs and measurement state for drawing arrows
  const containerRef = useRef<HTMLDivElement>(null);
  const nodeRefs = useRef<{ [id: string]: HTMLDivElement | null }>({});
  // Refs for scrollable sections
  const topRef = useRef<HTMLDivElement>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const leftRef = useRef<HTMLDivElement>(null);
  const [positions, setPositions] = useState<{ [id: string]: { x: number; y: number } }>({});
  const theBrain = useMemo(
    () => (apiKey && brainId ? new TheBrainAPI(apiKey, brainId) : null),
    [apiKey, brainId]
  );

  // Load graph when API/brainId/thoughtId ready
  useEffect(() => {
    if (!theBrain || !thoughtId) return;
    setError(null);
    setGraph(null);
    theBrain.getThoughtGraph({ thoughtId })
      .then((g) => setGraph(g as Graph))
      .catch((err) => {
        console.error('Error loading thought graph:', err);
        setError(err instanceof Error ? err.message : String(err));
      });
  }, [theBrain, thoughtId]);


  // Helper: measure node centers relative to container
  const measurePositions = () => {
    if (!graph) return;
    const rect = containerRef.current?.getBoundingClientRect();
    if (!rect) return;
    const newPos: typeof positions = {};
    Object.entries(nodeRefs.current).forEach(([id, el]) => {
      if (el) {
        const r = el.getBoundingClientRect();
        newPos[id] = {
          x: r.left + r.width / 2 - rect.left,
          y: r.top + r.height / 2 - rect.top,
        };
      }
    });
    setPositions(newPos);
  };
  // Center top/bottom scroll sections and measure positions when graph loads
  useLayoutEffect(() => {
    if (topRef.current) {
      const el = topRef.current;
      el.scrollLeft = (el.scrollWidth - el.clientWidth) / 2;
    }
    if (bottomRef.current) {
      const el = bottomRef.current;
      el.scrollLeft = (el.scrollWidth - el.clientWidth) / 2;
    }
    measurePositions();
  }, [graph]);
  // Re-measure on window resize
  useEffect(() => {
    window.addEventListener('resize', measurePositions);
    return () => window.removeEventListener('resize', measurePositions);
  }, []);

  const handleSelect = (id: string) => {
    if (onSelect) onSelect(id);
  };

  if (!apiKey || !brainId) {
    return (
      <div className="h-full flex items-center text-gray-400">
        Please configure TheBrain settings to view PLEX.
      </div>
    );
  }
  if (!thoughtId) {
    return (
      <div className="h-full flex items-center text-gray-400">
        Loading user thought...
      </div>
    );
  }
  if (error) {
    return (
      <div className="h-full p-4 text-red-500">Error loading graph: {error}</div>
    );
  }
  if (!graph) {
    return (
      <div className="h-full flex items-center text-gray-400">
        Loading graph...
      </div>
    );
  }

  const { activeThought, parents, children, jumps, links } = graph;
  // IDs for each section
  const parentIds = parents.map(n => n.id);
  const childIds = children.map(n => n.id);
  const jumpIds = jumps.map(n => n.id);

  // Position nodes: center active, parents above, children below, jumps left, links right
  return (
    <div ref={containerRef} className="relative w-full h-full bg-[#00100e] rounded-[20px]">
      {/* SVG overlay for arrows */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none z-0">
        <defs>
          <marker
            id="arrowhead"
            markerWidth="6"
            markerHeight="6"
            refX="5"
            refY="3"
            orient="auto"
            markerUnits="strokeWidth"
          >
            <path d="M0,0 L0,6 L6,3 z" fill="#14b8a6" />
          </marker>
        </defs>
        {/* Arrow to parents (top pane) */}
        {parentIds.map((pid) => {
          const start = positions[activeThought.id];
          const end = positions[pid];
          const el = nodeRefs.current[pid];
          const pane = topRef.current;
          if (!start || !end || !el || !pane) return null;
          const r = el.getBoundingClientRect();
          const pr = pane.getBoundingClientRect();
          // skip if target not visible in top pane viewport
          if (r.right < pr.left || r.left > pr.right) return null;
          return (
            <line
              key={`parent-${pid}`}
              x1={start.x}
              y1={start.y}
              x2={end.x}
              y2={end.y}
              stroke="#14b8a6"
              strokeWidth={2}
              markerEnd="url(#arrowhead)"
            />
          );
        })}
        {/* Arrow to children (bottom pane) */}
        {childIds.map((cid) => {
          const start = positions[activeThought.id];
          const end = positions[cid];
          const el = nodeRefs.current[cid];
          const pane = bottomRef.current;
          if (!start || !end || !el || !pane) return null;
          const r = el.getBoundingClientRect();
          const pr = pane.getBoundingClientRect();
          // skip if not visible horizontally in bottom pane viewport
          if (r.right < pr.left || r.left > pr.right) return null;
          return (
            <line
              key={`child-${cid}`}
              x1={start.x}
              y1={start.y}
              x2={end.x}
              y2={end.y}
              stroke="#14b8a6"
              strokeWidth={2}
              markerEnd="url(#arrowhead)"
            />
          );
        })}
        {/* Arrow to jumps (left pane) */}
        {jumpIds.map((jid) => {
          const start = positions[activeThought.id];
          const end = positions[jid];
          const el = nodeRefs.current[jid];
          const pane = leftRef.current;
          if (!start || !end || !el || !pane) return null;
          const r = el.getBoundingClientRect();
          const pr = pane.getBoundingClientRect();
          // skip if target not visible in left pane viewport
          if (r.bottom < pr.top || r.top > pr.bottom) return null;
          return (
            <line
              key={`jump-${jid}`}
              x1={start.x}
              y1={start.y}
              x2={end.x}
              y2={end.y}
              stroke="#14b8a6"
              strokeWidth={2}
              markerEnd="url(#arrowhead)"
            />
          );
        })}
        {/* Draw arrows for custom links between thoughts */}
        {graph.links.map((link) => {
          const start = positions[activeThought.id];
          const targetId = link.thoughtIdA === activeThought.id ? link.thoughtIdB : link.thoughtIdA;
          const end = positions[targetId];
          const el = nodeRefs.current[targetId];
          if (!start || !end || !el) return null;
          // determine which pane to check visibility
          let pane: HTMLDivElement | null = null;
          if (parentIds.includes(targetId)) pane = topRef.current;
          else if (childIds.includes(targetId)) pane = bottomRef.current;
          else if (jumpIds.includes(targetId)) pane = leftRef.current;
          // skip if target not visible in its pane
          if (pane) {
            const pr = pane.getBoundingClientRect();
            const r = el.getBoundingClientRect();
            if (r.bottom < pr.top || r.top > pr.bottom || r.right < pr.left || r.left > pr.right) return null;
          }
          const midX = (start.x + end.x) / 2;
          const midY = (start.y + end.y) / 2;
          return (
            <g key={`link-${link.id}`}> 
              <line
                x1={start.x}
                y1={start.y}
                x2={end.x}
                y2={end.y}
                stroke="#14b8a6"
                strokeWidth={2}
                markerEnd="url(#arrowhead)"
              />
              {link.name && (
                <text
                  x={midX}
                  y={midY}
                  fill="#ffffff"
                  fontSize="10"
                  textAnchor="middle"
                  alignmentBaseline="middle"
                  pointerEvents="none"
                >
                  {link.name}
                </text>
              )}
            </g>
          );
        })}
      </svg>
      {/* Active Thought at center */}
      <div
        ref={(el) => { nodeRefs.current[activeThought.id] = el; }}
        className="absolute cursor-pointer px-4 py-3 bg-gray-800 rounded text-center text-orange-400 hover:bg-orange-600 hover:text-white z-10"
        style={{ top: '50%', left: '50%', transform: 'translate(-50%, -50%)' }}
        onClick={() => handleSelect(activeThought.id)}
      >
        <div className="font-bold">{activeThought.name}</div>
        {activeThought.typeName && (
          <div className="text-[9px] font-bold text-gray-400 mt-1 uppercase">{activeThought.typeName}</div>
        )}
      </div>

      {/* Parents above center, scrollable if overflow */}
      {parents.length > 0 && (
        <div
          ref={topRef}
          className="absolute flex flex-nowrap items-center gap-2 overflow-x-auto z-10"
          style={{ top: 0, left: 0, width: '100%', height: '80px' }}
          onScroll={measurePositions}
        >
          {parents.map((node) => (
            <div
              ref={(el) => { nodeRefs.current[node.id] = el; }}
              key={node.id}
              className="flex-shrink-0 cursor-pointer px-2 py-1 bg-gray-800 rounded text-orange-400 hover:bg-orange-600 hover:text-white z-10 whitespace-nowrap"
              onClick={() => handleSelect(node.id)}
            >
              <div className="font-medium">{node.name}</div>
              {node.typeName && (
                <div className="text-[9px] font-bold text-gray-400 uppercase">{node.typeName}</div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Children below center, scrollable if overflow */}
      {children.length > 0 && (
        <div
          ref={bottomRef}
          className="absolute mx-5 flex flex-nowrap items-center gap-2 overflow-x-auto z-10"
          style={{ bottom: 0, left: 0, width: 'calc(100% - 20px)', height: '80px' }}
          onScroll={measurePositions}
        >
          {children.map((node) => (
            <div
              ref={(el) => { nodeRefs.current[node.id] = el; }}
              key={node.id}
              className="flex-shrink-0 cursor-pointer px-2 py-1 bg-gray-800 rounded text-orange-400 hover:bg-orange-600 hover:text-white z-10 whitespace-nowrap"
              onClick={() => handleSelect(node.id)}
            >
              <div className="font-medium">{node.name}</div>
              {node.typeName && (
                <div className="text-[9px] font-bold text-gray-400 uppercase">{node.typeName}</div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Jumps to the left of center, scrollable */}
      {jumps.length > 0 && (
        <div
          ref={leftRef}
          className="absolute mx-5 flex flex-col space-y-2 overflow-y-auto z-10"
          style={{ top: '120px', bottom: '120px', left: '0', width: '200px' }}
          onScroll={measurePositions}
        >
          {jumps.map((node) => (
            <div
              ref={(el) => { nodeRefs.current[node.id] = el; }}
              key={node.id}
              className="cursor-pointer px-2 py-1 bg-gray-800 rounded text-orange-400 hover:bg-orange-600 hover:text-white z-10 whitespace-nowrap"
              onClick={() => handleSelect(node.id)}
            >
              <div className="font-medium">{node.name}</div>
              {node.typeName && (
                <div className="text-[9px] font-bold text-gray-400 uppercase">{node.typeName}</div>
              )}
            </div>
          ))}
        </div>
      )}

    </div>
  );
};