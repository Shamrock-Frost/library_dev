/-
Copyright (c) 2015 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Robert Y. Lewis

The power operation on monoids and groups. We separate this from group, because it depends on
nat, which in turn depends on other parts of algebra.

We have "pow a n" for natural number powers, and "gpow a i" for integer powers. The notation
a^n is used for the first, but users can locally redefine it to gpow when needed.

Note: power adopts the convention that 0^0=1.
-/
import data.nat.basic data.int.basic ..tools.auto.finish 

universe u
variable {α : Type u}

class has_pow_nat (α : Type u) :=
(pow_nat : α → nat → α)

definition pow_nat {α : Type u} [s : has_pow_nat α] : α → nat → α :=
has_pow_nat.pow_nat

infix ` ^ ` := pow_nat

class has_pow_int (α : Type u) :=
(pow_int : α → int → α)

definition pow_int {α : Type u} [s : has_pow_int α] : α → int → α :=
has_pow_int.pow_int

 /- monoid -/
section monoid
open nat

variable [s : monoid α]
include s

definition monoid.pow (a : α) : ℕ → α
| 0     := 1
| (n+1) := a * monoid.pow n

instance monoid.has_pow_nat : has_pow_nat α :=
has_pow_nat.mk monoid.pow

@[simp] theorem pow_zero (a : α) : a^0 = 1 := rfl
@[simp] theorem pow_succ (a : α) (n : ℕ) : a^(succ n) = a * a^n := rfl
@[simp] theorem pow_one (a : α) : a^1 = a := mul_one _

theorem pow_succ' (a : α) : ∀ (n : ℕ), a^(succ n) = (a^n) * a 
| 0        := by simp 
| (succ n) :=
 suffices a * (a ^ n * a) = a * a ^ succ n, by simp [this],
 by rw -pow_succ'

@[simp] theorem one_pow : ∀ n : ℕ, (1 : α)^n = (1:α)
| 0        := rfl
| (succ n) := by simp; rw one_pow

theorem pow_add (a : α) : ∀ m n : ℕ, a^(m + n) = a^m * a^n 
| m 0 := by simp
| m (n+1) := by rw [add_succ, pow_succ', pow_succ', pow_add, mul_assoc]

theorem pow_mul (a : α) (m : ℕ) : ∀ n, a^(m * n) = (a^m)^n
| 0        := by simp
| (succ n) := by rw [nat.mul_succ, pow_add, pow_succ', pow_mul]

theorem pow_comm (a : α) (m n : ℕ)  : a^m * a^n = a^n * a^m :=
by rw [-pow_add, -pow_add, add_comm]

end monoid

/- commutative monoid -/

section comm_monoid
open nat
variable [s : comm_monoid α]
include s

theorem mul_pow (a b : α) : ∀ n, (a * b)^n = a^n * b^n
| 0        := by simp 
| (succ n) := by simp; rw mul_pow

end comm_monoid

section group
variable [s : group α]
include s

section nat
open nat
theorem inv_pow (a : α) : ∀n, (a⁻¹)^n = (a^n)⁻¹
| 0        := by simp
| (succ n) := by rw [pow_succ', _root_.pow_succ, mul_inv_rev, inv_pow] 

theorem pow_sub (a : α) {m n : ℕ} (h : m ≥ n) : a^(m - n) = a^m * (a^n)⁻¹ :=
have h1 : m - n + n = m, from nat.sub_add_cancel h,
have h2 : a^(m - n) * a^n = a^m, by rw [-pow_add, h1],
eq_mul_inv_of_mul_eq h2

theorem pow_inv_comm (a : α) : ∀m n, (a⁻¹)^m * a^n = a^n * (a⁻¹)^m
| 0 n               := by simp
| m 0               := by simp
| (succ m) (succ n) := calc
  a⁻¹ ^ succ m * a ^ succ n = (a⁻¹ ^ m * a⁻¹) * (a * a^n) : by rw [pow_succ', _root_.pow_succ]
                        ... = a⁻¹ ^ m * (a⁻¹ * a) * a^n : by simp
                        ... = a⁻¹ ^ m * a^n : by simp
                        ... = a ^ n * (a⁻¹)^m : by rw pow_inv_comm
                        ... = a ^ n * (a * a⁻¹) * (a⁻¹)^m : by simp
                        ... = (a^n * a) * (a⁻¹ * (a⁻¹)^m) : by simp only [mul_assoc]
                        ... = a ^ succ n * a⁻¹ ^ succ m : by rw [pow_succ', _root_.pow_succ]; simp

end nat

open int


definition gpow (a : α) : ℤ → α
| (of_nat n) := a^n
| -[1+n]     := (a^(nat.succ n))⁻¹

local attribute [ematch] le_of_lt
open nat
private lemma gpow_add_aux (a : α) (m n : nat) :
  gpow a ((of_nat m) + -[1+n]) = gpow a (of_nat m) * gpow a (-[1+n]) :=
or.elim (nat.lt_or_ge m (nat.succ n))
 (suppose m < succ n,
  have m ≤ n, from le_of_lt_succ this,
  suffices gpow a -[1+ n-m] = (gpow a (of_nat m)) * (gpow a -[1+n]), by simp [*, of_nat_add_neg_succ_of_nat_of_lt],
  suffices (a^(nat.succ (n - m)))⁻¹ = (gpow a (of_nat m)) * (gpow a -[1+n]), from this,
  suffices (a^(nat.succ n - m))⁻¹ = (gpow a (of_nat m)) * (gpow a -[1+n]), by rw -succ_sub; assumption,
  by rw pow_sub; finish [gpow])
 (suppose m ≥ succ n,
  suffices gpow a (of_nat (m - succ n)) = (gpow a (of_nat m)) * (gpow a -[1+ n]), 
    by rw [of_nat_add_neg_succ_of_nat_of_ge]; assumption,
  suffices a ^ (m - succ n) = a^m * (a^succ n)⁻¹, from this,
  by rw pow_sub; assumption)


theorem gpow_add (a : α) : ∀i j : int, gpow a (i + j) = gpow a i * gpow a j
| (of_nat m) (of_nat n) := pow_add _ _ _
| (of_nat m) -[1+n]     := gpow_add_aux _ _ _
| -[1+m]     (of_nat n) := begin rw [add_comm, gpow_add_aux], unfold gpow, rw [-inv_pow, pow_inv_comm] end
| -[1+m]     -[1+n]     := 
  suffices (a ^ (m + succ (succ n)))⁻¹ = (a ^ succ m)⁻¹ * (a ^ succ n)⁻¹, from this,
  by rw [-succ_add_eq_succ_add, add_comm, pow_add, mul_inv_rev]


theorem gpow_comm (a : α) (i j : ℤ) : gpow a i * gpow a j = gpow a j * gpow a i :=
by rw [-gpow_add, -gpow_add, add_comm]
end group

section ordered_ring
open nat
variable [s : linear_ordered_ring α]
include s

theorem pow_pos {a : α} (H : a > 0) : ∀ (n : ℕ), a ^ n > 0 
| 0 := by simp; apply zero_lt_one
| (succ n) := begin simp, apply mul_pos, assumption, apply pow_pos end

theorem pow_ge_one_of_ge_one {a : α} (H : a ≥ 1) : ∀ (n : ℕ), a ^ n ≥ 1 
| 0 := by simp; apply le_refl
| (succ n) := 
  begin 
   simp, rw -(one_mul (1 : α)), 
   apply mul_le_mul, 
   assumption,
   apply pow_ge_one_of_ge_one,  
   apply zero_le_one,
   transitivity, apply zero_le_one, assumption
  end

end ordered_ring

