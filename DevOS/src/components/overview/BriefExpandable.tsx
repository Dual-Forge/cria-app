'use client';

import { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';

interface BriefExpandableProps {
  contentHtml: string;
}

export function BriefExpandable({ contentHtml }: BriefExpandableProps) {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="relative">
      <div
        className={`overflow-hidden transition-all duration-300 ${expanded ? '' : 'max-h-72'}`}
        style={{ maskImage: expanded ? 'none' : 'linear-gradient(to bottom, black 60%, transparent 100%)' }}
      >
        <div
          className="prose prose-invert prose-p:text-muted-foreground prose-headings:font-bold prose-headings:tracking-tight prose-a:text-primary max-w-none"
          dangerouslySetInnerHTML={{ __html: contentHtml }}
        />
      </div>
      <button
        onClick={() => setExpanded(!expanded)}
        className="mt-4 flex items-center gap-2 text-xs font-mono uppercase tracking-widest text-primary border border-primary px-4 py-2 hover:bg-primary hover:text-primary-foreground transition-none w-full justify-center"
      >
        {expanded ? (
          <><ChevronUp className="w-3.5 h-3.5" /> Recolher</>
        ) : (
          <><ChevronDown className="w-3.5 h-3.5" /> Ver Documento Completo</>
        )}
      </button>
    </div>
  );
}
