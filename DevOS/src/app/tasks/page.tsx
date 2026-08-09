import { getTasks, Task } from '@/lib/parser';
import { Badge } from '@/components/ui/badge';

function TaskCard({ task, variant }: { task: Task, variant: 'todo'|'progress'|'done' }) {
  const borderColors = {
    todo: 'border-border',
    progress: 'border-blue-500',
    done: 'border-primary'
  };
  
  return (
    <div className={`p-4 border-2 ${borderColors[variant]} bg-card hover:bg-accent/5 transition-none relative group`}>
      <div className={`absolute top-0 left-0 w-2 h-full ${variant === 'todo' ? 'bg-border' : variant === 'progress' ? 'bg-blue-500' : 'bg-primary'}`} />
      <div className="pl-4">
        <div className="text-[10px] font-mono text-muted-foreground uppercase tracking-widest mb-2">{task.id}</div>
        <p className="text-sm font-bold leading-snug text-foreground">{task.name}</p>
      </div>
    </div>
  );
}

export default async function TasksPage() {
  const sprints = await getTasks();
  
  return (
    <div className="p-12 h-full flex flex-col max-w-[1600px] mx-auto">
      <header className="space-y-4 border-b-2 border-primary pb-8 mb-12 shrink-0">
        <h1 className="text-6xl font-black tracking-tighter uppercase">Task Board_</h1>
        <p className="text-primary font-mono uppercase tracking-widest">Kanban Sink // Read-Only // Extracted from PROJECT_TASKS.md</p>
      </header>
      
      <div className="flex-1 overflow-auto space-y-16 pb-12">
        {Object.keys(sprints).length === 0 && (
          <div className="text-center p-12 border-2 border-dashed border-border text-muted-foreground font-mono uppercase">
            [SYS_MSG] Nenhuma tarefa processada.
          </div>
        )}
        
        {Object.entries(sprints).map(([sprintName, tasks]) => {
          const todo = tasks.filter(t => t.status === 'To Do');
          const inProgress = tasks.filter(t => t.status === 'In Progress');
          const done = tasks.filter(t => t.status === 'Done');
          
          return (
            <section key={sprintName} className="space-y-8">
              <h2 className="text-3xl font-bold flex items-center gap-4 uppercase tracking-tighter border-l-4 border-primary pl-4">
                {sprintName}
                <span className="text-sm font-mono bg-primary text-primary-foreground px-2 py-1">{tasks.length} TASKS</span>
              </h2>
              
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
                {/* TO DO */}
                <div className="border border-border bg-background p-6">
                  <h3 className="font-black mb-6 text-xl uppercase tracking-tighter flex items-center justify-between border-b border-border pb-4">
                    To Do
                    <span className="font-mono text-muted-foreground">{todo.length}</span>
                  </h3>
                  <div className="space-y-4">
                    {todo.map(t => <TaskCard key={t.id} task={t} variant="todo" />)}
                  </div>
                </div>
                
                {/* IN PROGRESS */}
                <div className="border border-blue-900/30 bg-blue-950/10 p-6">
                  <h3 className="font-black mb-6 text-xl text-blue-500 uppercase tracking-tighter flex items-center justify-between border-b border-blue-900/30 pb-4">
                    In Progress
                    <span className="font-mono">{inProgress.length}</span>
                  </h3>
                  <div className="space-y-4">
                    {inProgress.map(t => <TaskCard key={t.id} task={t} variant="progress" />)}
                  </div>
                </div>
                
                {/* DONE */}
                <div className="border border-primary/30 bg-primary/5 p-6">
                  <h3 className="font-black mb-6 text-xl text-primary uppercase tracking-tighter flex items-center justify-between border-b border-primary/30 pb-4">
                    Done
                    <span className="font-mono">{done.length}</span>
                  </h3>
                  <div className="space-y-4">
                    {done.map(t => <TaskCard key={t.id} task={t} variant="done" />)}
                  </div>
                </div>
              </div>
            </section>
          );
        })}
      </div>
    </div>
  );
}
