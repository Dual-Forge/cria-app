import { getParsedDocument, getStatusInfo, ProgressItem } from '@/lib/parser';
import { BriefExpandable } from '@/components/overview/BriefExpandable';
import {
  Activity, Clock, AlertTriangle, Zap, CheckCircle2, Package,
  ArrowRight, GitBranch, CalendarClock, Info, ShieldAlert
} from 'lucide-react';

// ─── Status Badge ────────────────────────────────────────────────────────────
function StatusBadge({ status }: { status: string }) {
  const isDone = status.includes('✅') || status.toLowerCase().includes('concluíd');
  const isActive = status.includes('🟡') || status.toLowerCase().includes('desenvolvimento');
  const isPaused = status.includes('⛔');
  const color = isDone
    ? 'bg-primary/10 text-primary border-primary/30'
    : isPaused
    ? 'bg-destructive/10 text-destructive border-destructive/30'
    : isActive
    ? 'bg-blue-500/10 text-blue-400 border-blue-500/30'
    : 'bg-muted text-muted-foreground border-border';
  return (
    <span className={`inline-flex items-center px-3 py-1 text-xs font-mono uppercase tracking-widest border ${color}`}>
      {status}
    </span>
  );
}

// ─── Module Status Dot ────────────────────────────────────────────────────────
function ModuleStatusDot({ status }: { status: string }) {
  if (status === 'Concluído') return <span className="w-2 h-2 rounded-full bg-primary shrink-0 mt-0.5" />;
  if (status === 'Em andamento') return <span className="w-2 h-2 rounded-full bg-blue-500 shrink-0 mt-0.5" />;
  if (status === 'Bloqueado') return <span className="w-2 h-2 rounded-full bg-destructive shrink-0 mt-0.5" />;
  return <span className="w-2 h-2 rounded-full bg-border shrink-0 mt-0.5" />;
}

// ─── Progress Grid ────────────────────────────────────────────────────────────
function ProgressGrid({ items }: { items: ProgressItem[] }) {
  return (
    <div className="grid grid-cols-2 gap-x-8 gap-y-5">
      {items.map(item => (
        <div key={item.label} className="space-y-2">
          <div className="flex items-center justify-between gap-2">
            <span className="text-xs font-mono uppercase tracking-wider text-muted-foreground truncate">{item.label}</span>
            <span className={`text-sm font-black shrink-0 tabular-nums ${item.value === 100 ? 'text-primary' : item.value > 0 ? 'text-blue-400' : 'text-muted-foreground/40'}`}>
              {item.value}%
            </span>
          </div>
          <div className="h-[3px] w-full bg-border">
            <div
              className={`h-full ${item.value === 100 ? 'bg-primary' : item.value > 0 ? 'bg-blue-500' : 'bg-border'}`}
              style={{ width: `${Math.max(item.value, 0)}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────
function Card({ children, className = '', accent = false }: { children: React.ReactNode; className?: string; accent?: boolean }) {
  return (
    <div className={`border ${accent ? 'border-2 border-primary/40' : 'border-border'} bg-card p-6 space-y-4 ${className}`}>
      {children}
    </div>
  );
}

function CardHeader({ icon: Icon, label, color = 'text-primary' }: { icon: React.ElementType; label: string; color?: string }) {
  return (
    <div className={`flex items-center gap-2 ${color}`}>
      <Icon className="w-4 h-4" />
      <span className="text-xs font-mono uppercase tracking-widest">{label}</span>
    </div>
  );
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default async function OverviewPage() {
  const brief = await getParsedDocument('PROJECT_BRIEF.md');
  const s = await getStatusInfo();

  return (
    <div className="p-12 max-w-7xl mx-auto space-y-12">

      {/* ── Header ── */}
      <header className="space-y-4 border-b-2 border-primary pb-8">
        <div className="flex items-start justify-between gap-8 flex-wrap">
          <div className="space-y-2">
            <h1 className="text-6xl font-black tracking-tighter uppercase">Project Overview_</h1>
            <p className="text-primary font-mono uppercase tracking-widest text-sm">Visão Executiva // Status Global</p>
          </div>
          {s && (
            <div className="text-right shrink-0 space-y-2">
              <p className="text-xs font-mono text-muted-foreground uppercase tracking-widest">{s.projectName}</p>
              <p className="text-3xl font-black font-mono">{s.version}</p>
              <StatusBadge status={s.generalStatus} />
            </div>
          )}
        </div>
      </header>

      {s && (
        <section className="space-y-4">
          <h2 className="text-2xl font-bold tracking-tighter uppercase border-l-4 border-primary pl-4">Status Atual</h2>

          {/* ── ROW 1: Sprint · Last Activity · Next Activity ── */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

            {/* Sprint Atual */}
            <Card accent>
              <CardHeader icon={GitBranch} label="Sprint Atual" />
              <div className="space-y-2">
                <p className="text-base font-black tracking-tight leading-snug">{s.currentSprintTitle}</p>
                {s.currentSprintStatus && (
                  <StatusBadge status={s.currentSprintStatus} />
                )}
              </div>
              {s.sprintObjective && (
                <p className="text-xs text-muted-foreground leading-relaxed border-t border-border pt-3">{s.sprintObjective}</p>
              )}
            </Card>

            {/* Última Atividade */}
            <Card>
              <CardHeader icon={Clock} label="Última Atividade" color="text-blue-400" />
              {s.lastActivityDate && (
                <p className="text-xs font-mono text-primary">{s.lastActivityDate}</p>
              )}
              <p className="text-xs text-muted-foreground leading-relaxed line-clamp-5">{s.lastActivity || '—'}</p>
            </Card>

            {/* Próxima Atividade */}
            <Card>
              <CardHeader icon={ArrowRight} label="Próxima Atividade" />
              <p className="text-xs text-muted-foreground leading-relaxed">{s.nextActivity || '—'}</p>
            </Card>
          </div>

          {/* ── ROW 2: Progresso + Bloqueios ── */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

            {/* Progresso Geral — full width on left */}
            {s.progress.length > 0 && (
              <Card className="lg:col-span-2">
                <CardHeader icon={Activity} label="Progresso Geral" />
                <ProgressGrid items={s.progress} />
              </Card>
            )}

            {/* Bloqueios */}
            <Card className={s.blockers.length > 0 ? 'border-destructive/30' : ''}>
              <CardHeader
                icon={ShieldAlert}
                label="Bloqueios"
                color={s.blockers.length > 0 ? 'text-destructive' : 'text-muted-foreground'}
              />
              {s.blockers.length === 0 ? (
                <div className="flex items-center gap-2 text-primary">
                  <CheckCircle2 className="w-4 h-4" />
                  <p className="text-sm font-mono">Nenhum bloqueio.</p>
                </div>
              ) : (
                <ul className="space-y-2">
                  {s.blockers.map((b, i) => (
                    <li key={i} className="flex items-start gap-2 text-xs text-destructive">
                      <AlertTriangle className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                      <span>{b}</span>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          </div>

          {/* ── ROW 3: Módulos + Últimas Decisões ── */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {/* Módulos */}
            {s.modules.length > 0 && (
              <Card>
                <CardHeader icon={Package} label="Módulos" />
                <div className="grid grid-cols-1 gap-1.5 max-h-60 overflow-y-auto pr-1">
                  {s.modules.map((mod) => (
                    <div key={mod.name} className="flex items-start gap-2.5 py-0.5">
                      <ModuleStatusDot status={mod.status} />
                      <div className="min-w-0">
                        <p className="text-xs text-foreground leading-tight truncate" title={mod.name}>{mod.name}</p>
                        <p className="text-[10px] font-mono text-muted-foreground uppercase">{mod.status}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </Card>
            )}

            {/* Últimas Decisões */}
            {s.recentDecisions.length > 0 && (
              <Card>
                <CardHeader icon={Zap} label="Últimas Decisões" />
                <ul className="space-y-3">
                  {s.recentDecisions.map((d, i) => (
                    <li key={i} className="flex items-start gap-2.5 text-xs text-muted-foreground">
                      <CheckCircle2 className="w-3.5 h-3.5 text-primary shrink-0 mt-0.5" />
                      <span>{d}</span>
                    </li>
                  ))}
                </ul>
              </Card>
            )}
          </div>

          {/* ── ROW 4: Próxima Revisão + Observações ── */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {/* Próxima Revisão */}
            {s.nextRevision && (
              <Card>
                <CardHeader icon={CalendarClock} label="Próxima Revisão" color="text-blue-400" />
                <p className="text-sm font-mono text-foreground">{s.nextRevision}</p>
              </Card>
            )}

            {/* Observações */}
            {s.observations.length > 0 && (
              <Card>
                <CardHeader icon={Info} label="Observações" color="text-muted-foreground" />
                <ul className="space-y-2">
                  {s.observations.map((obs, i) => (
                    <li key={i} className="flex items-start gap-2.5 text-xs text-muted-foreground">
                      <span className="text-primary mt-0.5 shrink-0">•</span>
                      <span>{obs}</span>
                    </li>
                  ))}
                </ul>
              </Card>
            )}
          </div>
        </section>
      )}

      {/* ── Project Brief (Expandable) ── */}
      <section className="space-y-6">
        <h2 className="text-2xl font-bold tracking-tighter uppercase border-l-4 border-primary pl-4">Project Brief</h2>
        {brief.error ? (
          <div className="p-4 bg-destructive text-destructive-foreground text-sm font-mono">{brief.error}</div>
        ) : (
          <div className="border border-border bg-card p-8">
            <BriefExpandable contentHtml={brief.contentHtml} />
          </div>
        )}
      </section>
    </div>
  );
}
