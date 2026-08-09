import { getDocsTree, DocNode, getParsedDocument } from '@/lib/parser';
import Link from 'next/link';
import { ScrollArea } from '@/components/ui/scroll-area';
import { FileText, Folder, SquareTerminal } from 'lucide-react';

function Tree({ nodes }: { nodes: DocNode[] }) {
  return (
    <ul className="space-y-0 border-l border-border pl-0 ml-2">
      {nodes.map(node => (
        <li key={node.path} className="relative group">
          <div className="absolute -left-[1px] top-0 bottom-0 w-[2px] bg-primary opacity-0 group-hover:opacity-100 transition-none" />
          {node.isDir ? (
            <div className="pl-4 mt-2 mb-1">
              <span className="flex items-center gap-2 text-[10px] font-bold py-1 text-foreground uppercase tracking-widest">
                <Folder className="w-3.5 h-3.5 text-primary" /> {node.name}
              </span>
              {node.children && <Tree nodes={node.children} />}
            </div>
          ) : (
            <Link href={`/docs?file=${encodeURIComponent(node.path)}`} className="flex items-center gap-2 text-sm py-1.5 hover:text-primary transition-none pl-4 text-muted-foreground font-mono text-xs">
              <FileText className="w-3 h-3 shrink-0 opacity-50 group-hover:opacity-100" /> <span className="truncate">{node.name}</span>
            </Link>
          )}
        </li>
      ))}
    </ul>
  );
}

export default async function DocsPage(props: { searchParams: Promise<{ file?: string }> }) {
  const searchParams = await props.searchParams;
  const file = searchParams?.file;
  const tree = await getDocsTree();
  
  let doc = null;
  if (file) {
    doc = await getParsedDocument(file);
  }

  return (
    <div className="flex h-full">
      <div className="w-72 border-r border-border bg-background shrink-0">
        <ScrollArea className="h-full">
          <div className="p-6">
            <h2 className="font-bold mb-6 text-xs uppercase tracking-widest text-primary flex items-center gap-2">
              <SquareTerminal className="w-4 h-4" /> REPOSITÓRIO
            </h2>
            <div className="-ml-2">
              <Tree nodes={tree} />
            </div>
          </div>
        </ScrollArea>
      </div>
      
      <div className="flex-1 overflow-auto bg-card">
        {doc ? (
          <div className="max-w-5xl mx-auto p-12">
            <header className="mb-12 border-b-2 border-primary pb-6">
              <p className="text-primary font-mono text-xs mb-2 uppercase tracking-widest">{doc.filePath}</p>
              <h1 className="text-5xl font-black tracking-tighter uppercase">{doc.metadata?.title || doc.filePath.split('/').pop()?.replace('.md', '')}</h1>
            </header>
            
            {doc.error ? (
              <div className="p-4 bg-destructive text-destructive-foreground border-l-4 border-foreground">
                <strong className="font-mono uppercase tracking-widest block mb-2">Fatal Error</strong>
                {doc.error}
              </div>
            ) : (
              <div 
                className="prose prose-invert prose-p:text-muted-foreground prose-headings:text-foreground prose-headings:font-bold prose-headings:tracking-tight prose-a:text-primary prose-a:no-underline hover:prose-a:underline prose-code:text-primary prose-pre:bg-background prose-pre:border prose-pre:border-border max-w-none w-full"
                dangerouslySetInnerHTML={{ __html: doc.contentHtml }} 
              />
            )}
          </div>
        ) : (
          <div className="h-full flex items-center justify-center text-muted-foreground">
            <div className="text-center space-y-4">
              <SquareTerminal className="w-16 h-16 mx-auto text-border" />
              <p className="font-mono text-sm uppercase tracking-widest">Aguardando Seleção de Arquivo...</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
