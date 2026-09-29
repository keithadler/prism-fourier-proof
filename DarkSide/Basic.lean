/-
Copyright (c) 2026 Keith Adler. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Keith Adler
-/
import Mathlib

/-!
# A Lean proof of "Dark Side of the Moon"

The famous prism cover, read as physics: white light is a **sum of frequencies**
(a Fourier decomposition), the glass disperses each frequency to a different
angle, and the screen shows the **Fourier spectrum** `|Ê(ω)|²`.

We formalize panel 1 (the decomposition) and panel 3 (the intensity).
-/

open scoped BigOperators

namespace DarkSide

/-- A spectrum: finitely many modes, each with a real amplitude `aₖ`,
    angular frequency `ωₖ`, and phase `φₖ`. -/
structure Spectrum (n : ℕ) where
  amp : Fin n → ℝ
  freq : Fin n → ℝ
  phase : Fin n → ℝ

variable {n : ℕ}

/-- **Panel 1.** The real light signal `E(t) = Σₖ aₖ cos(ωₖ t + φₖ)`. -/
noncomputable def signal (S : Spectrum n) (t : ℝ) : ℝ :=
  ∑ k, S.amp k * Real.cos (S.freq k * t + S.phase k)

/-- The complex Fourier amplitude `Ê(ωₖ) = aₖ e^{i φₖ}`: the phasor of mode `k`. -/
noncomputable def phasor (S : Spectrum n) (k : Fin n) : ℂ :=
  (S.amp k : ℂ) * Complex.exp ((S.phase k : ℂ) * Complex.I)

/-- **Panel 3 (the screen).** The intensity of mode `k` is `|Ê(ωₖ)|² = aₖ²`. -/
theorem intensity (S : Spectrum n) (k : Fin n) :
    Complex.normSq (phasor S k) = (S.amp k) ^ 2 := by
  unfold phasor
  rw [Complex.normSq_mul, Complex.normSq_ofReal]
  have h : Complex.normSq (Complex.exp ((S.phase k : ℂ) * Complex.I)) = 1 := by
    rw [Complex.normSq_apply, Complex.exp_ofReal_mul_I_re, Complex.exp_ofReal_mul_I_im]
    nlinarith [Real.sin_sq_add_cos_sq (S.phase k)]
  rw [h]; ring

/-- Each mode is the real part of its rotating phasor `cₖ e^{i ωₖ t}`. -/
theorem mode_reconstruction (S : Spectrum n) (k : Fin n) (t : ℝ) :
    (phasor S k * Complex.exp ((S.freq k : ℂ) * (t : ℂ) * Complex.I)).re
      = S.amp k * Real.cos (S.freq k * t + S.phase k) := by
  unfold phasor
  rw [mul_assoc, ← Complex.exp_add]
  have hsum : (S.phase k : ℂ) * Complex.I + (S.freq k : ℂ) * (t : ℂ) * Complex.I
      = ((S.freq k * t + S.phase k : ℝ) : ℂ) * Complex.I := by
    push_cast; ring
  rw [hsum, Complex.re_ofReal_mul, Complex.exp_ofReal_mul_I_re]

/-- **Panel 1 ⇄ Panel 3.** The whole signal is the real part of the sum of its
    rotating Fourier phasors. -/
theorem signal_eq_sum_phasors (S : Spectrum n) (t : ℝ) :
    signal S t
      = (∑ k, phasor S k * Complex.exp ((S.freq k : ℂ) * (t : ℂ) * Complex.I)).re := by
  rw [Complex.re_sum]
  unfold signal
  refine Finset.sum_congr rfl ?_
  intro k _
  exact (mode_reconstruction S k t).symm

end DarkSide
