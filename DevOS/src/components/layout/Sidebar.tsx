import Link from 'next/link';
import { Home, ListTodo, FileText, AlertTriangle, Terminal } from 'lucide-react';

export function Sidebar() {
  return (
    <div className="w-64 h-screen border-r border-border bg-card flex flex-col sticky top-0 shrink-0">
      <div className="h-16 flex items-center px-6 border-b border-border bg-background">
        <Terminal className="w-5 h-5 mr-3 text-primary" />
        <span className="font-bold text-lg tracking-tighter uppercase text-foreground">DevOS_</span>
      </div>
      <nav className="flex-1 p-4 space-y-1 text-sm font-medium">
        <Link href="/" className="group flex items-center gap-3 px-3 py-3 text-muted-foreground hover:text-foreground transition-none border-l-2 border-transparent hover:border-primary hover:bg-accent/10">
          <Home className="w-4 h-4 group-hover:text-primary transition-none" /> 
          <span className="uppercase tracking-widest text-xs">Overview</span>
        </Link>
        <Link href="/tasks" className="group flex items-center gap-3 px-3 py-3 text-muted-foreground hover:text-foreground transition-none border-l-2 border-transparent hover:border-primary hover:bg-accent/10">
          <ListTodo className="w-4 h-4 group-hover:text-primary transition-none" /> 
          <span className="uppercase tracking-widest text-xs">Task Board</span>
        </Link>
        <Link href="/docs" className="group flex items-center gap-3 px-3 py-3 text-muted-foreground hover:text-foreground transition-none border-l-2 border-transparent hover:border-primary hover:bg-accent/10">
          <FileText className="w-4 h-4 group-hover:text-primary transition-none" /> 
          <span className="uppercase tracking-widest text-xs">Docs Explorer</span>
        </Link>
        <Link href="/debt" className="group flex items-center gap-3 px-3 py-3 text-muted-foreground hover:text-foreground transition-none border-l-2 border-transparent hover:border-primary hover:bg-accent/10">
          <AlertTriangle className="w-4 h-4 group-hover:text-primary transition-none" /> 
          <span className="uppercase tracking-widest text-xs">Tech Debt</span>
        </Link>
      </nav>
      <div className="p-4 border-t border-border text-xs text-muted-foreground font-mono">
        v2.0 // BRUTALIST
      </div>
    </div>
  );
}
