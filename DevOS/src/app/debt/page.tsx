import { getTechDebt } from '@/lib/parser';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import Link from 'next/link';

export default async function DebtPage() {
  const debts = await getTechDebt();

  return (
    <div className="p-12 h-full flex flex-col max-w-7xl mx-auto">
      <header className="space-y-4 border-b-2 border-primary pb-8 mb-12 shrink-0">
        <h1 className="text-6xl font-black tracking-tighter uppercase">Tech Debt Panel_</h1>
        <p className="text-primary font-mono uppercase tracking-widest">Scanner Recursivo // TODO & FIXME Logs</p>
      </header>
      
      <div className="flex-1 overflow-auto">
        {debts.length === 0 ? (
          <div className="p-12 text-center border-2 border-dashed border-border text-muted-foreground font-mono uppercase">
            [SYS_MSG] Nenhuma dívida técnica encontrada. Código limpo.
          </div>
        ) : (
          <div className="border-2 border-border bg-card">
            <Table>
              <TableHeader className="bg-background">
                <TableRow className="border-b-2 border-border hover:bg-transparent">
                  <TableHead className="w-[120px] font-bold uppercase tracking-widest text-xs text-foreground">Type</TableHead>
                  <TableHead className="font-bold uppercase tracking-widest text-xs text-foreground">File Path</TableHead>
                  <TableHead className="w-[100px] font-bold uppercase tracking-widest text-xs text-foreground text-right">Line</TableHead>
                  <TableHead className="font-bold uppercase tracking-widest text-xs text-foreground">Context Block</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {debts.map((debt, idx) => (
                  <TableRow key={`${debt.file}-${idx}`} className="border-border hover:bg-accent/5 transition-none">
                    <TableCell>
                      <span className={`px-2 py-1 text-[10px] font-mono uppercase tracking-widest font-bold ${debt.type === 'TODO' ? 'bg-secondary text-secondary-foreground' : 'bg-destructive text-destructive-foreground'}`}>
                        {debt.type}
                      </span>
                    </TableCell>
                    <TableCell className="font-mono text-xs">
                      {debt.file.endsWith('.md') ? (
                        <Link href={`/docs?file=${encodeURIComponent(debt.file)}`} className="text-primary hover:underline hover:bg-primary/10 px-1 -mx-1">
                          {debt.file}
                        </Link>
                      ) : (
                        <span className="text-muted-foreground">{debt.file}</span>
                      )}
                    </TableCell>
                    <TableCell className="font-mono text-xs text-right text-muted-foreground">L:{debt.line}</TableCell>
                    <TableCell className="font-mono text-xs">
                      <span className="bg-muted px-2 py-1 truncate max-w-[400px] inline-block align-bottom" title={debt.text}>
                        {debt.text || <span className="opacity-50"># NO_CONTEXT</span>}
                      </span>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </div>
    </div>
  );
}
