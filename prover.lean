import clause prover_state
import subsumption misc_preprocessing
import resolution factoring clausifier
open monad tactic expr

declare_trace resolution
set_option trace.resolution false

meta_definition trace_clauses : resolution_prover unit := do
state ← stateT.read,
resolution_prover_of_tactic (tactic.trace state)

meta_definition run_prover_loop
  (literal_selection : selection_strategy)
  (clause_selection : resolution_prover name)
  (preprocessing_rules : list (resolution_prover unit))
  (inference_rules : list inference)
  : unit → resolution_prover (option expr) | () := do
sequence' preprocessing_rules,
new ← take_newly_derived, forM' new register_as_passive,
passive : rb_map name cls ← get_passive,
if rb_map.size passive = 0 then return none else do
given_name ← clause_selection,
given ← option.to_monad (rb_map.find passive given_name),
-- trace_clauses,
remove_passive given_name,
if is_false (cls.type given) = tt then return (some (cls.prf given)) else do
selected_lits ← literal_selection given,
activated_given ← return $ active_cls.mk given_name selected_lits given,
resolution_prover_of_tactic (when (is_trace_enabled_for `resolution = tt) (do
  fmt ← pp activated_given, trace (to_fmt "given: " ++ fmt))),
add_active activated_given,
seq_inferences inference_rules activated_given,
run_prover_loop ()

meta_definition default_preprocessing : list (resolution_prover unit) :=
[
tautology_removal_pre,
subsumption_interreduction_pre,
forward_subsumption_pre
]

meta_definition default_inferences : list inference :=
[
forward_subsumption, backward_subsumption,
clausification_inference,
resolution_inf, factor_inf
]

meta_definition try_clausify (prf : expr) : tactic (list cls) :=
(do c ← cls.of_proof prf, return [c]) <|> return []

meta_definition prover_tactic : tactic unit := do
intros,
target_name ← get_unused_name `target none, tgt ← target,
mk_mapp ``classical.by_contradiction [some tgt] >>= apply, intro target_name,
hyps ← local_context,
initial_clauses ← mapM try_clausify hyps,
initial_state ← resolution_prover_state.initial (join initial_clauses),
res ← run_prover_loop selection21 weight_clause_selection
  default_preprocessing default_inferences
  () initial_state,
match res with
| (some empty_clause, _) := apply empty_clause
| (none, saturation) := trace "saturation" >> trace saturation >> skip
end
