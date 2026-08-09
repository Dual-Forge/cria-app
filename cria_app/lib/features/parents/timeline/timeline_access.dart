/// Escopo de acesso à Linha do Tempo.
///
/// Prepara o app para a injeção futura de regras de controle de acesso (RBAC).
/// A próxima iteração introduzirá um "Modo Convidado" (acesso via convite por
/// e-mail) com permissão apenas de visualização, curtir e comentar. Nenhum
/// convidado poderá criar, editar ou excluir memórias.
///
/// Toda a destruição/edição habilitada hoje para pais é registrada aqui para
/// que os widgets já nasçam prontos: basta ligar o `canManage` do convidado
/// em `false` na mesma lógica que injeta o acesso.
enum TimelineAccessScope {
  /// Proprietário / pais da família: acesso total (CRUD de memórias).
  owner,

  /// Convidado (Modo Convidado, futura iteração): leitura, curtir e comentar.
  guest;
}

/// Resolve o modo de acesso do usuário atual sobre a linha do tempo.
///
/// Hoje o app só possui pais autenticados, portanto o retorno é sempre
/// [TimelineAccessScope.owner]. Quando o Modo Convidado for implementado,
/// este resolver passará a derivar a permissão a partir da sessão de convite
/// — os widgets já estarão preparados, pois leem [canManage]/[canEdit]
/// em vez de decidirem por conta própria.
class TimelineAccess {
  const TimelineAccess._();

  static TimelineAccessScope of() => TimelineAccessScope.owner;
}

/// Views conveniência para evitar espalhar `scope ==` pelos widgets.
extension TimelineAccessScopeX on TimelineAccessScope {
  /// Pode criar, editar e excluir memórias.
  bool get canManage => this == TimelineAccessScope.owner;

  /// Pode acessar o menu de contexto da memória (Editar / Definir perfil / Excluir).
  bool get canEdit => this == TimelineAccessScope.owner;
}