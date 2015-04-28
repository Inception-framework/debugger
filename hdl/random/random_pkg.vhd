--   **********************************************************************
--   *  This Software Package was developed for internal use within       *
--   *  McDonnell Douglas Corporation (MDC). MDC and the authors or       *
--   *  distributers of this code are not responsible for correctnes or   *
--   *  accuracy of the procedures/functions in this package. This code   *
--   *  may not be distributed for commercial purposes. IN NO EVENT SHALL *
--   *  MDC BE LIABLE FOR ANY INCIDENTAL, INDIRECT , SPECIAL, OR          *
--   *  CONSEQUENTIAL DAMAGES WHATSOEVER ARISING OUT OF OR RELATING TO    *
--   *  THE USE OF THE INFORMATION/SOFTWARE PROVIDED IN THIS PACKAGE.     *
--   **********************************************************************

Package RANDOM Is

    --------------------------------------------------------------------------
    --                                                                      --
    --  Random Number Generation Package                                    --
    --                                                                      --
    --  Authors:                                                            --
    --      John A. Breen, Ken Christensen                                  --
    --  McDonnell Douglas Missile Systems Company, July 1989                --
    --          Dept E435, Bldg 111/2/N-3, (314)234-4341                    --
    --  Updates/Distribution:                                               --
    --      William A. Hanna                                                --
    --  McDonnell Douglas Aerospace-Defense & Electronic Systems, Nov. 1993 --
    --       MC 500 4224                                                    --
    --       MDA-D&ES                                                       --
    --       P.O.Box 426                                                    --
    --       St. Charles, MO 63302                                          --
    --                                                                      --
    --                                                                      --
    --  Date: 12-July-1989                                                  --
    --                                                                      --
    --  This package contains routines for generating random numbers from   --
    --  14 different discrete and uniform distributions.  Each distribution --
    --  is accessed through a single procedure call, Rnd_Random.  All       --
    --  parameters to this procedure are passed via a record of type        --
    --  rnd_rec_t, with the exception of the empirical array, which is      --
    --  optional (We would have liked to include the array in the record,   --
    --  but VHDL does not allow record fields to be unconstrained arrays).  --
    --  It would have been nice if we could have made Rnd_Random a function --
    --  instead of a procedure, but the subprogram has to modify the seed,  --
    --  and VHDL doesn't allow functions to modify their parameters.        --
    --                                                                      --
    --  In addition, there is a procedure for loading a rnd_rec_t record    --
    --  from an ASCII file; this routine is named Rnd_Read_Record, and takes--
    --  two parameters: the file variable, and the record to be loaded.     --
    --                                                                      --
    --  The basic random number generator, from which all of the various    --
    --  distributions are derived, is a mixed linear congruential generator --
    --  with a 48-bit seed (in fact, it emulates the UNIX System V function --
    --  erand48).  To make it easier for the user to choose independent     --
    --  initial seeds, a constant array, rnd_seeds, is provided, which the  --
    --  user can specify directly in his models (although Rnd_Read_Rec      --
    --  isn't smart enough to recognize it in an ASCII file, at least not   --
    --  yet).                                                               --
    --                                                                      --
    --  Dependencies: Removed in this version!                              --
    --      Package TEXTIO                                                  --
    --      A math package (in this implementation called C_MATH) which     --
    --      contains the following functions:                               --
    --          Log(x)      (natural log)                                   --
    --          Ceil(x)     (smallest integral value >= x)                  --
    --          Floor(x)    (largest integral value <= x)                   --
    --          SqRt(x)     (exponentiation with Real exponent)             --
    --          "**"(x, y)  (exponentiation with Real exponent)             --
    --      Each of these functions takes Real arguments and returns a      --
    --      Real.  We cheated a little by "hooking" in the UNIX math        --
    --      library, but there was no easy way around it.                   --
    --                                                                      --
    --  This package was developed for MDC internal use only. Public Use    --
    --  Is Subject to Resrictions as Stated In the First Paragraph of this  --
    --  Document.                                                           --
    --------------------------------------------------------------------------

--  Use Std.textIO.Text;  -- Some Tools Require This Line
    Use STD.TEXTIO.ALL;   -- Other VHDL Tolls Require This Instead
 
    Type rnd_distribution_t Is (
        --
        -- Discrete distributions
        --
        rnd_constant,       -- Constant value (always returns the mean)
        rnd_uniform_d,      -- Integer uniform, [bound_l, bound_h)
        rnd_poisson,
        rnd_binomial,
        rnd_geometric,
        rnd_empirical_d,  -- User-specified array (cumulative distribution)
        --
        -- Continuous distributions
        --
        rnd_uniform_c,    -- Real uniform, [bound_l, bound_h)
        rnd_normal,
        rnd_triangular,
        rnd_exponential,
        rnd_hyperexponential,
        rnd_gamma,
        rnd_erlang,
        rnd_empirical_c   -- User-specified array (cumulative distribution)
    );

    Type rnd_seed_t Is Array (3 downto 0) of Integer;
    Type rnd_seed_vector_t Is Array (Positive Range <>) of rnd_seed_t;
    Type rnd_empirical_t Is Record
        x: Real;        -- Value of random variable
        p: Real;        -- cumulative probability of value x
    End Record;
    Type rnd_empirical_vector_t Is Array (Natural Range <>) of rnd_empirical_t;
    Type rnd_rec_t Is Record
        rnd: Real;
        distribution: rnd_distribution_t;
        seed: rnd_seed_t;
        mean, std_dev: Real;
        bound_l, bound_h: Real;
        trials: Integer;
        p_success: Real;
    End Record;
-- ------------------------------------------------------------------------

-- VHDL CODING OF MATH FUNCTIONS.
-- WE RECOMMEND THE USE OF A MATH LIBRARY IF ONE IS AVAILABLE

-- SQRT Is A Square Root Polynomial Type Function
--  Function SQRT (X:Real) return Real;

-- Natural Logarithm
-- Function Log (X:Real) return Real;

-- Exponential Function
-- Function Exp (X: Real) return Real;

-- Exponential Function #2
-- Function "**" (X,Y: Real) return Real;

-- Floor Function
-- Function Floor (X:Real) return Real;

-- Ceil Function
-- Function Ceil (X:Real) return Real;
-- ---------------------------------------------------------------------

--  Procedure Rnd_Read_Record(file_f: Text; rnd_rec: inout rnd_rec_t);
      Procedure Rnd_Read_Record(rnd_rec: inout rnd_rec_t);

    Procedure Rnd_Random(
        rnd_rec: InOut rnd_rec_t;
        empirical_data: In rnd_empirical_vector_t := (0 => (0.0, 0.0), 1 => (1.0, 1.0)));
                -- V-Systems Does Not Like Initial Values
                -- := (0 => (0.0, 0.0), 1 => (1.0, 1.0)));

 Constant rnd_seeds: rnd_seed_vector_t(1 to 50) := (
   (  80, 2466, 2681, 2459), (  62,  493,  536,  699), (1430, 2639, 3931, 3035),
   ( 153, 2415, 2756, 1275), (3114, 3364, 3281, 3611), (2389, 3195, 3588, 1851),
   (3616, 2485, 1756,   91), (4015, 1093, 4056, 2427), (4022, 2774,  378,  667),
   (1343, 3394, 1088, 3003), (2234, 3739,  172, 1243), (2914, 1828, 3900, 3579),
   ( 494, 1624, 2162, 1819), (2711, 1250, 1229,   59), (1641, 1698, 3276, 2395),
   (3559, 3246, 2289,  635), (2303, 1870,  442, 2971), ( 586, 2045, 4009, 1211),
   (3491,  878, 2876, 3547), (2567,  900, 3317, 1787), (1738, 2392, 3411,   27),
   (1050, 3895, 1237, 2363), (1746, 2720, 3069,  603), (1947, 3657, 2889, 2939),
   (1379, 3098, 2875, 1179), ( 797, 1840, 1105, 3515), (2261, 1498, 3853, 1755),
   (  20,  927, 1005, 4091), ( 914,  821, 2931, 2331), (2618,  138, 3614,  571),
   (1404,  703, 1133, 2907), (2801, 3623, 1762, 1147), ( 336, 1611, 3579, 3483),
   (2219, 4073,  570, 1723), (1547,  751, 3101, 4059), (2633, 3204, 1062, 2299),
   (3148,  255,  724,  539), (3713, 3565,  166, 2875), (1977, 3086, 1566, 1115),
   (1860,  343, 3002, 3451), (3174,  753, 2556, 1691), (2333, 1848, 2402, 4027),
   (2098, 1981,  622, 2267), (3740,  835, 3487,  507), (  50, 4037,  884, 2843),
   (4019, 3181, 3183, 1083), ( 531,  926,  270, 3419), (3360, 3306, 2515, 1659),
   (2425, 3867, 3900, 3995), (4045,  558, 2507, 2235)
    );
End RANDOM;

    Library RANDOM_LIB;
--    Use Utility.C_Math.All;
    Use RANDOM_LIB.all;
    Library IEEE;
    use IEEE.MATH_REAL.all;
Package Body RANDOM Is

    Constant rnd_lcg_a: rnd_seed_t := (16#0#, 16#5DE#, 16#ECE#, 16#66D#);

    Constant rnd_lcg_c: rnd_seed_t := (16#0#, 16#0#, 16#0#, 16#B#);

    Constant rnd_lcg_m: Integer := 2**12;
-- ----------------------------------------------------------------------

-- Body of Math Functions within VHDL!
-- VHDL CODING OF MATH FUNCTIONS. WE RECOMMEND THE USE OF A MATH LIBRARY
-- IF ONE IS AVAILABLE

-- SQRT Is A Square Root Polynomial Type Function
--  Function SQRT (X:Real) return Real Is
--  Variable A: Real; -- TEMP for Evaluation
--  begin
--    A:=0.25497+X*(0.11722-X*(0.67206+X*(0.30750-X*(0.62662))));
--    return A;
--  end;
-- -------------------------------------------------------------------

-- Natural Logarithm
-- Function Log (X:REal) return Real Is
-- Variable A: Real := 0.0; -- TEMP for Evaluation
-- begin
--   A :=0.2+X*(0.66666+X*(0.40020+X*(0.28233+X*(0.25095
--              -X*(0.55393+X*(0.41272 ))))));
--   return A;
-- end;
-- ---------------------------------------------------------------------

-- Exponential Function

-- Function Exp (X: Real) return Real Is
-- Variable A: Real :=1.0; -- TEMP for Evaluation
-- begin
--   A:= 1.0+X*(1.0+X*(1.0/2.0+X*(1.0/6.0+X*(1.0/24.0))));
--   return A;
-- end;
-- ---------------------------------------------------------------------

-- Exponential Function #2
-- Function "**" (X,Y: Real) return Real Is
-- Variable A: Real:=1.0; -- TEMP for Evaluation
-- begin
--   A := exp ( Y * Log (X));
--   return A;
-- end;
-- ---------------------------------------------------------------------

-- Floor Function
-- Function Floor (X:Real) return Real Is
-- Variable A: Real:=0.0; -- TEMP for Evaluation
-- begin
--   for i in -32768.0 to 32767.0 loop
--   if X>Real(i) then  A:=Real(i)-1.0; return A;
--   else A:=Real(i);
--   end if;
--   end loop;
--   return A;
-- end;
-- -------------------------------------------------------------------

-- Ceil Function
-- Function Ceil (X:Real) return Real Is
-- Variable A: Real:=0.0; -- TEMP for Evaluation
-- begin
--   for i in -32768.0 to 32767.0 loop
--   if X>Real(i) then  A:=Real(i)+1.0; return A;
--   else A:=Real(i);
--   end if;
--   end loop;
--   return A;
-- end;
-- -------------------------------------------------------------------

    Procedure rnd48(rnd: Out Real; seed: InOut rnd_seed_t) Is
    ------------------------------------------------------------------
    --Rnd48 : Receives a 48 bit number, the seed, and returns a     --
    --        random number between 0 and 1.                        --
    --                                                              --
    --Reference : Domain/IX Programmer's Reference for System V.    --
    --            Apollo Computer Inc.                              --
    --                                                              --
    --Used Fields : rnd, seed.                                      --
    --                                                              --
    --Changed Fields : rnd, seed.                                   --
    ------------------------------------------------------------------

    Variable i : integer;

        Function Mult(rnd_lcg_b : rnd_seed_t) return rnd_seed_t is
            Variable temp : rnd_seed_t;
            Variable i, j : integer;
        Begin
           for i in 0 to 3 loop
               temp(i) := 0;
           end loop;

           for i in 0 to 3 loop
               for j in 0 to (3 - i) loop
                  temp(i + j) := temp(i + j) + (rnd_lcg_a(i) * rnd_lcg_b(j));
               end loop;
           end loop;

           for i in 0 to 2 loop
               if temp(i) >= rnd_lcg_m then
                    temp(i + 1) := temp(i + 1) + ( temp(i) / rnd_lcg_m);
                    temp(i) := temp(i) mod rnd_lcg_m;
               end if;
           end loop;

           temp(3) := temp(3) mod rnd_lcg_m;
           return temp;
        End Mult;

        Function Add(x : rnd_seed_t) return rnd_seed_t is
            Variable tempa : rnd_seed_t;
            Variable i     : integer;
        Begin

           for i in 0 to 3 loop
               tempa(i) := x(i) + rnd_lcg_c(i);
           end loop;

           for i in 0 to 2 loop
               if tempa(i) >= rnd_lcg_m then
                    tempa(i +1) := tempa(i +1) + (tempa(i) / rnd_lcg_m);
                    tempa(i) := tempa(i) mod rnd_lcg_m;
               end if;
          end loop;

            tempa(3) := x(3) mod rnd_lcg_m;
            return tempa;
        End Add;
    Begin
        For i in 0 to 3 loop
            If seed(i) >= rnd_lcg_m then
                Assert False
                    Report "The seed element must be less than the 4096"
                    Severity Warning;
                seed(i) := seed(i) mod rnd_lcg_m;
            Elsif
                Seed(i) < 0 then
                Assert False
                    Report "The seed must be a positive number"
                    Severity Warning;
                seed(i) := (-seed(i)) mod rnd_lcg_m;
            End if;
        End loop;
        seed := add(mult(seed));
        rnd := ((((Real(seed(0)) / Real(rnd_lcg_m)
               + Real(seed(1))) / Real(rnd_lcg_m) + Real(seed(2))) /
               Real(rnd_lcg_m) + Real(seed(3))) / Real(rnd_lcg_m));
    End rnd48;

    Procedure uniform_d(rnd_rec: InOut rnd_rec_t) Is
    -----------------------------------------------------------------
    --uniform_d : Generate a uniformly distributed integer         --
    --            random number in the range [bound_l, bound_h).   --
    --                                                             --
    --Used Fields : seed, bound_l, bound_h.                        --
    --                                                             --
    --Changed Fields : rnd, seed.                                  --
    -----------------------------------------------------------------

    Variable tmp : real;

    Begin

        If (rnd_rec.bound_l > rnd_rec.bound_h) then
            Assert False
            Report "Lower bound is greater than the upper bound."
            Severity Warning;
            rnd_rec.rnd := rnd_rec.bound_h;
        Elsif (rnd_rec.bound_l /= real(integer(rnd_rec.bound_l))) or
            (rnd_rec.bound_h /= real(integer(rnd_rec.bound_h))) then
            Assert False
            Report "The lower and upper bounds are not integer numbers"
            Severity Warning;
            rnd_rec.rnd := floor(rnd_rec.bound_h);
        Else
            rnd48(tmp, rnd_rec.seed);
            rnd_rec.rnd := rnd_rec.bound_l + floor
                       ((rnd_rec.bound_h + 1.0 - rnd_rec.bound_l) * tmp);
        End if;
    End uniform_d;

    Procedure poisson(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --poisson : Generate a random number from the Poisson         --
    --          distribution.                                     --
    --                                                            --
    --Reference : Lavenberg, computer performance modeling hand-  --
    --            book, 1983, section 5.2.1, algorithm 5.4.       --
    --                                                            --
    --Used Fields : mean, seed.                                   --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable temp, term, sum, x : real;

    Begin
        If (rnd_rec.mean >  0.0) then
            x := 0.0;
            rnd48(temp, rnd_rec.seed);
            term := Exp(-rnd_rec.mean);

            If (term > 0.0) then
                sum := term;

                While temp > sum loop
                    x := x + 1.0;
                    term := rnd_rec.mean / x * term;
                    sum := sum + term;
                End loop;
                rnd_rec.rnd := x;
                          Else
                Assert False
                Report " The mean is too large"
                Severity Warning;
                rnd_rec.rnd := rnd_rec.mean;
            End if;

        Else
           Assert False
             Report "The mean must be greater than zero"
             Severity Warning;
           rnd_rec.rnd := rnd_rec.mean;
        End if;
    End poisson;

    Procedure binomial(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --binomial : Generate a random number from the Binomial       --
    --           Distribution with the trials having a probability--
    --           for success, p_success.                          --
    --                                                            --
    --Reference : Lavenburg, computer performance modeling hand-  --
    --            book, 1983, section 5.2.1, algorithm 5.7.       --
    --                                                            --
    --Used Fields : trials, p_success, seed.                      --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable ngood,temp   : real;
    Variable i            :integer;

    Begin

         If ((rnd_rec.p_success >= 0.0) and (rnd_rec.p_success <= 1.0)) then

             If rnd_rec.trials >= 1 then
                 ngood := 0.0;

                 For i in 1 to rnd_rec.trials loop
                     rnd48(temp, rnd_rec.seed);

                     If (temp < rnd_rec.p_success) then
                         ngood := ngood + 1.0;
                     End if;
                     rnd_rec.rnd := ngood;
                 End loop;
             Else
                 Assert False
                 Report "The number of trials must be a positive integer"
                 Severity Warning;
                 rnd_rec.rnd := 0.0;
             End if;
         Else
             Assert False
             Report "The probability of success must be between zero and one"
             Severity Warning;
             rnd_rec.rnd := 0.0;
         End if;
    End binomial;

    Procedure geometric(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --geometric : Generate a random number from the Geometric     --
    --            Distribution with probability of success,       --
    --            p_success.                                      --
    --                                                            --
    --Reference : Lavenberg, computer performance modeling hand-  --
    --             book, 1983, section 5.2.1,                     --
    --                                                            --
    --Used Fields : seed, p_success.                              --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable rgeom, temp : real;

    Begin
        If ((rnd_rec.p_success > 0.0) and (rnd_rec.p_success <= 1.0)) then

            If (rnd_rec.p_success < 1.0) then
                rnd48(temp, rnd_rec.seed);
                rnd_rec.rnd := ceil(log(temp) / log(1.0 - rnd_rec.p_success));
            Else
                rnd_rec.rnd := 1.0;
            End if;
        Else
            Assert False
            Report "The probability of success must be between zero and one"
            Severity Warning;
            rnd_rec.rnd := 0.0;
        End if;
    End geometric;

    Procedure empirical_d(rnd_rec: InOut rnd_rec_t;
                          emp_data: In rnd_empirical_vector_t) Is
    ----------------------------------------------------------------
    --empirical_d : Generate a random number from the cumulative  --
    --              distribution specified in emp_data.  The last --
    --              element of this array must have a probability --
    --              of 1.0; the first element must have a         --
    --              probability GREATER than 0.                   --
    --                                                            --
    --Used Fields : seed                                          --
    --                                                            --
    --Changed Fields : rnd, seed                                  --
    ----------------------------------------------------------------

        Variable u: Real;
        Variable i: Integer;

    Begin
       If ((emp_data'Length = 0) Or (emp_data'Left > emp_data'Right)) Then
           Assert False
               Report "An ascending array of empirical data must be given"
               Severity Warning;
           rnd_rec.rnd := 0.0;
       Elsif (emp_data(emp_data'Left).p <= 0.0) Then
          Assert False
            Report "The first data point's probability must be greater than 0.0"
            Severity Warning;
          rnd_rec.rnd := 0.0;
       Elsif (emp_data(emp_data'Right).p /= 1.0) Then
          Assert False
             Report "The last data point's probability must be 1.0"
             Severity Warning;
          rnd_rec.rnd := 0.0;
        Else
            rnd48(u, rnd_rec.seed);
            i := emp_data'Left;
            While (emp_data(i).p < u) Loop
                i := i + 1;
            End Loop;
            rnd_rec.rnd := emp_data(i).x;
        End If;
    End empirical_d;

    Procedure uniform_c(rnd_rec: InOut rnd_rec_t) Is
    --------------------------------------------------------------------------
    --  uniform_c: Generate a uniformly distributed random number           --
    --      in the range [bound_l, bound_h)                                 --
    --                                                                      --
    --  Used fields: seed, bound_l, bound_h                                 --
    --                                                                      --
    --  Changed fields: rnd, seed                                           --
    --------------------------------------------------------------------------

        Variable tmp_rnd: Real;

    Begin
        If (rnd_rec.bound_l > rnd_rec.bound_h) Then
            Assert False
                Report "Lower bound is greater than upper bound."
                Severity Warning;
            rnd_rec.rnd := rnd_rec.bound_h;
        Else
            rnd48(tmp_rnd, rnd_rec.seed);
            rnd_rec.rnd := tmp_rnd * (rnd_rec.bound_h - rnd_rec.bound_l)
            + rnd_rec.bound_l;
        End If;
    End uniform_c;

    Procedure normal(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --normal : Generate a random number from the Normal           --
    --         Distribution(polar method).                        --
    --                                                            --
    --Reference : Lavenberg, computer performance modeling hand-  --
    --            book, 1983, polar method.                       --
    --                                                            --
    --Used Fields : std_dev, seed, mean.                          --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable temp1, temp2, v1, v2, s : real;

    Begin
        s := 1.0;

        While s >= 1.0  loop
            rnd48(temp1, rnd_rec.seed);
            rnd48(temp2, rnd_rec.seed);
            v1 := 2.0 * temp1 - 1.0;
            v2 := 2.0 * temp2 - 1.0;
            s := v1 * v1 + v2 * v2;
        end loop;

        If rnd_rec.std_dev < 0.0 then
            Assert False
            Report "The standard deviation must be a positive number"
            Severity Warning;
            rnd_rec.rnd := rnd_rec.mean;
        Else
            rnd_rec.rnd := rnd_rec.std_dev * v1 * sqrt((-2.0 * log(s)) / s)
                       + rnd_rec.mean;
        End if;
    End normal;

    Procedure triangular(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --triangle : Generate a random number from the Triangular     --
    --           Distribution.                                    --
    --                                                            --
    --Reference : Pritsker, introduction to simulation and        --
    --            Slam II, 1984, appendix g.                      --
    --                                                            --
    --Used Fields : mean, bound_l, bound_h, seed.                 --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable temp : real;

    Begin
        If (rnd_rec.bound_l < rnd_rec.bound_h) and
            (rnd_rec.bound_l < rnd_rec.mean) and
            (rnd_rec.mean < rnd_rec.bound_h) then

            rnd48(temp, rnd_rec.seed);

            If (temp > ((rnd_rec.mean - rnd_rec.bound_l) /
               (rnd_rec.bound_h - rnd_rec.bound_l))) then

                 rnd_rec.rnd := rnd_rec.bound_h - sqrt
                           ((rnd_rec.bound_h - rnd_rec.mean) *
              (rnd_rec.bound_h - rnd_rec.bound_l) * (1.0 - temp));
              Else
                  rnd_rec.rnd := rnd_rec.bound_l + sqrt((rnd_rec.mean
                                 - rnd_rec.bound_l) * (rnd_rec.bound_h
                                 - rnd_rec.bound_l) * temp);
           End if;
        Else
            Assert False
                Report "Improper lower bound, upper bound, or mean"
                Severity Warning;
                rnd_rec.rnd := rnd_rec.mean;
        End if;
    End triangular;

    Procedure hyperexponential(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --hyperexponential : Generate a hyperexponentially            --
    --                   Distributed random number.               --
    --                                                            --
    --Used Fields : mean, std_dev, seed.                          --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable coeff, cosq, p, fac, temp, temp1 : real;

    Begin
        If ((rnd_rec.mean <= 0.0) or (rnd_rec.std_dev <= 0.0)) then
            Assert False
            Report "The mean and standard deviation must be positive"
            Severity Warning;
            rnd_rec.rnd := 1.0;
        Else
           coeff := rnd_rec.std_dev / rnd_rec.mean;

           If coeff < 1.0 then
              Assert False Report
                "The ratio of the deviation to the mean must be greater than 1"
                Severity Warning;
              rnd_rec.rnd := rnd_rec.mean;
            Else
                cosq := coeff * coeff;
                p := (1.0 + (cosq) - sqrt(cosq * cosq - 1.0)) /
                     (2.0 * (1.0 + cosq));

                If ((p <= 0.0) or (p > 1.0)) then
                    Assert False
                    Report "Improper mean and standard deviation"
                    Severity Warning;
                    rnd_rec.rnd := rnd_rec.mean;
                Else
                    fac := 1.0 / (2.0 * p);
                    rnd48(temp, rnd_rec.seed);

                    If (temp > p) then
                        fac := 1.0 / (2.0 * (1.0 - p));
                    End if;

                    rnd48(temp1, rnd_Rec.seed);
                    rnd_rec.rnd := (-rnd_rec.mean * fac) * log(temp1);

                End if;
            End if;
        End if;
    End hyperexponential;

    Procedure gamma(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --gamma : Generate a random number from the Gamma             --
    --        Distibution.                                        --
    --                                                            --
    --Reference : Pritsker, simulation and Slam II, 1984          --
    --            Cheng, "The generation of gamma variables with  --
    --            nonintegeral shape parameters," applied         --
    --            statistics, vol 26, no 1, 1977, pp 71-75.       --
    --                                                            --
    --Used Fields : mean, std_dev, seed.                          --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable accept                         : boolean;
    Variable temp1, temp2, alpha, ra, a, b  : real;
    Variable rima, beta, x, y, w, c, v, z, r: real;

    Begin

        If rnd_rec.mean <= 0.0 then
            Assert False
              Report "The mean must be greater than zero"
              Severity Warning;
            rnd_rec.rnd := 1.0;
        Elsif
            rnd_rec.std_dev <= 0.0 then
            Assert False
            Report " The standard deviation must be greater than zero"
            Severity Warning;
            rnd_rec.rnd := rnd_rec.mean;
        Else
            alpha := (rnd_rec.mean * rnd_rec.mean) /
                     (rnd_rec.std_dev * rnd_rec.std_dev);

            If alpha < 1.0 then
                ra := 1.0 / alpha;
                rima := 1.0 / (1.0 - alpha);
                beta := rnd_rec.mean / alpha;
                x := 1.0;
                y := 1.0;

                While x + y > 1.0 loop
                    rnd48(temp1, rnd_rec.seed);
                    rnd48(temp2, rnd_rec.seed);
                    x := temp1 ** ra;
                    y := temp2 ** rima;
                End loop;

                w := x / (x + y);
                rnd48(temp1, rnd_rec.seed);
                rnd_rec.rnd := w * (-log(temp1)) * beta;
            Elsif
                alpha <= 1.0 then
                rnd48(temp1, rnd_rec.seed);
                rnd_rec.rnd := -rnd_rec.mean * log(temp1);
            Else
                a := 1.0 / sqrt(2.0 * alpha - 1.0);
                b := alpha - log(4.0);
                c := Alpha + 1.0 / a;
                accept := false;

                While not accept loop
                    rnd48(temp1, rnd_rec.seed);
                    rnd48(temp2, rnd_rec.seed);
                    v := a * log(temp1 / (1.0 - temp1));
                    x := alpha * exp(v);
                    z := temp1 * temp1 * temp2;
                    r := b + c * v - x;
                    accept := ((r + 2.5040774 - 4.5 * z) >= 0.0
                              or (r > log(z)));
                    End loop;

                    rnd_rec.rnd := rnd_rec.std_dev * rnd_rec.std_dev
                                   / rnd_rec.mean * x;
            End if;
        End if;
    End gamma;

    Procedure erlang(rnd_rec: InOut rnd_rec_t) Is
    ----------------------------------------------------------------
    --erlang : Generate a random number from a generalized        --
    --         Erlang distribution.                               --
    --                                                            --
    --Used Fields : mean, std_dev, seed.                          --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable  coeff, fn, cfsq, p, tranx : real;
    Variable temp1, temp2, stgmn, cumlog: real;
    Variable n, i                       : integer;
    Constant rnd_min                    : real := 1.0E-25;

    Begin
        If(rnd_rec.mean <= 0.0) or (rnd_rec.std_dev <= 0.0) then
           Assert False
             Report "The mean and the standard deviation must be positive"
             Severity Warning;
           rnd_rec.rnd := 1.0;
           Return;
        End if;

        coeff := rnd_rec.std_dev / rnd_rec.mean;

        If coeff > 1.0 then
           Assert False Report
             "The ratio of standard deviation to the mean must be less than one"
             Severity Warning;
           rnd_rec.rnd := rnd_rec.mean;
           Return;
        End if;

        fn := 1.0 / (coeff * coeff);
        n := Integer(floor(fn));

        If fn /= real(n) then n := n + 1;

            If n = 1 then n := 2;
            End if;

            fn := real(n);
            cfsq := coeff * coeff;
            p := ((2.0 * fn * cfsq) + fn - 2.0 - sqrt((fn * fn) + 4.0
                 - (4.0 * fn * cfsq))) / (2.0 * (cfsq + 1.0) * (fn - 1.0));

            If (p < 0.0) or (p > 1.0) then
                Assert False
                  Report "Improper mean and standard deviation"
                  Severity Warning;
                rnd_rec.rnd := rnd_rec.mean;
                Return;
            End if;
        Else
            p := 0.0;
        End if;
        stgmn := rnd_Rec.mean / (fn - p * (fn - 1.0));
        rnd48(temp1, rnd_rec.seed);
        cumlog := 0.0;

        If p = 0.0 then tranx := 0.0;
        Else
            rnd48(tranx, rnd_rec.seed);
        End if;

        If (tranx >= p) and (n > 1) then

            For i in 2 to n loop
                If temp1 <= rnd_min then
                    cumlog := cumlog + log(temp1);
                    temp1 := 1.0;
                End if;
                rnd48(temp2, rnd_rec.seed);
                temp1 := temp1 * temp2;
            End loop;

        End if;
        rnd_rec.rnd := (-stgmn) * (cumlog + log(temp1));
    End erlang;

    Procedure exponential(rnd_rec: Inout rnd_rec_t) Is
    ----------------------------------------------------------------
    --exponential : Generate a random number exponentially        --
    --              distributed.                                  --
    --                                                            --
    --Used Fields : mean seed.                                    --
    --                                                            --
    --Changed Fields : rnd, seed.                                 --
    ----------------------------------------------------------------

    Variable temp : real;

    Begin
         If rnd_rec.mean <= 0.0 then
             Assert False
               Report "The mean must be a positive number"
               Severity Warning;
         End if;
         temp := 0.0;

         While temp = 0.0 loop
             rnd48(temp, rnd_rec.seed);
         End loop;

         rnd_rec.rnd := -rnd_rec.mean * log(temp);
    End exponential;


    Procedure empirical_c(rnd_rec: InOut rnd_rec_t;
                          emp_data: In rnd_empirical_vector_t) Is
    ----------------------------------------------------------------
    --empirical_c : Generate a random number from the cumulative  --
    --              distribution specified in emp_data.  The last --
    --              element of this array must have a probability --
    --              of 1.0; the first element must have a         --
    --              probability of 0.0.                           --
    --                                                            --
    --Used Fields : seed                                          --
    --                                                            --
    --Changed Fields : rnd, seed                                  --
    ----------------------------------------------------------------

        Variable u: Real;
        Variable i: Integer;

    Begin
       If ((emp_data'Length = 0) Or (emp_data'Left > emp_data'Right)) Then
          Assert False
             Report "An ascending array of empirical data must be given"
             Severity Warning;
          rnd_rec.rnd := 0.0;
        Elsif (emp_data(emp_data'Left).p /= 0.0) Then
            Assert False
                Report "The first data point's probability must be 0.0"
                Severity Warning;
            rnd_rec.rnd := 0.0;
        Elsif (emp_data(emp_data'Right).p /= 1.0) Then
            Assert False
                Report "The last data point's probability must be 1.0"
                Severity Warning;
            rnd_rec.rnd := 0.0;
        Else
            rnd48(u, rnd_rec.seed);
            i := emp_data'Left + 1;
            While (emp_data(i).p < u) Loop
                i := i + 1;
            End Loop;
            rnd_rec.rnd := (u - emp_data(i - 1).p) / (emp_data(i).p - emp_data(i - 1).p)
                * (emp_data(i).x - emp_data(i - 1).x) + emp_data(i - 1).x;
        End If;
    End empirical_c;
-------------------------------------------------------------------------------
--  For some reason, this code causes some VHDL compilers to crash;
--  since it's rarely (if ever) used, we originally left it out.
--  I reinistated it as a test case for V-System. B. Hanna 11/18/93
--  It seems to work now, the collbrate is passing FILE Variables!!!
--  Procedure Rnd_Read_Record(file_f: Text; rnd_rec: inOut rnd_rec_t) Is

    Procedure Rnd_Read_Record(rnd_rec: inOut rnd_rec_t) Is
--    ----------------------------------------------------------------
--    --rnd_read_rec : This procedure is called to read data from a --
--    --             file that the user calls.  This procedure then --
--    --             calls the procedures rnd_reead_character and   --
--    --             random_dist1.  The data is then checked against--
--    --             the fields of the record rnd_rec_t and stored  --
--    --             as those field.                                --
--    ----------------------------------------------------------------

        Use Std.TextIO.All;
        Type rnd_rec1_t is (mean, distribution, std_dev, trials, seed,
            rnd, bound_l, bound_h, p_success);
        Type rnd_lead_array is array(rnd_rec1_t) of string(1 to 21);
        Constant rnd_lead : rnd_lead_array :=
          ( "mean                 ",
            "distribution         ",
            "std_dev              ",
            "trials               ",
            "seed                 ",
            "rnd                  ",
            "bound_l              ",
            "bound_h              ",
            "p_success            " );

        Variable read_str, read_str1, read_str2, read_str3, read_str4 : string(1 to 21);
        Variable l, lpr: Line;
        Variable check : boolean;
--        File f : Text is out "rnd.out";
        Variable i, int : integer;

     Procedure rnd_read_character(l: inout line; read_str: inout string(1 to 21)) is
--        ----------------------------------------------------------------
--        --rnd_read_character : Called to read the data file and store --
--        --                   the data. While reading the file,  blank --
--        --                   spaces are thrown out.                   --
--        ----------------------------------------------------------------

        Variable i, j : integer;
        Variable space: character;
        Variable check: boolean;
        variable ld   : line;

        Begin
          If (l'Length = 0) Then

             For j in 1 to 21 loop
                 read_str(j) := ' ';
             End loop;

            Else
              read(l, space, check);

                If check = true then
                    While (space = ' ') And (l'Length /= 0) loop
                       read(l, space);
                    End loop;
                    read_str(1) := space;
                    i := 2;
                    While i <= 21 loop
                        If (l'Length = 0) Then
                            Exit;
                        End If;
                        Read(l, read_str(i));

                        If read_str(i) = ' ' then
                            Exit;
                        End if;
                        i := i + 1;
                    End loop;

                    For j in i to 21 loop
                        read_str(j) := ' ';
                    End loop;
                Else
                    Assert False
                    Report "Error in reading the data file"
                    Severity Warning;
                End if;
            End if;
        End rnd_read_character;
--
     Procedure random_dist1(rnd_rec : inout rnd_rec_t; l : inout line) Is
--     ----------------------------------------------------------------
--     --random_dist1 : The data read is checked against  all of the --
--     --              distributions and are stored in the record    --
--     --              field of rnd_rec.distribution                 --
--     ----------------------------------------------------------------

        Type Dist_str_array is array(rnd_distribution_t) of string(1 to 21);
        Constant dist_str : Dist_str_array :=
          ( "rnd_constant         ",
            "rnd_uniform_d        ",
            "rnd_poisson          ",
            "rnd_binomial         ",
            "rnd_geometric        ",
            "rnd_empirical_d      ",
            "rnd_uniform_c        ",
            "rnd_normal           ",
            "rnd_triangular       ",
            "rnd_exponential      ",
            "rnd_hyperexponential ",
            "rnd_gamma            ",
            "rnd_erlang           ",
            "rnd_empirical_c      "  );

        Variable dist : String(1 to 21);
        variable lpr  : line;
        Variable check: boolean;
        variable i    : rnd_distribution_t;

        Begin
           rnd_read_character(l, dist);
           For i in rnd_distribution_t loop

              If dist = (dist_str(i)) then
                  rnd_rec.distribution := i;
                  exit;
              End if;

              Assert i /= rnd_distribution_t'High
                 Report "Unrecognized distribution found"
                 Severity Warning;
           End loop;
       End random_dist1;

       File file_f: Text;
       variable status: FILE_OPEN_STATUS;
    Begin

       FILE_OPEN(status, file_f, "XYZ.IN", READ_MODE);
       Assert status = OPEN_OK
         report "Could not open file XYZ.IN"
         Severity failure;
       While not Endfile(file_f) loop
           readline(file_f, l);
           rnd_read_character(l, read_str);
           For i in rnd_rec1_t loop
               If read_str = rnd_lead(i) then
                  If rnd_lead(i) = rnd_lead(seed) then
                     read(l, int);
                     rnd_rec.seed(0) := int;
                     read(l, int);
                     rnd_rec.seed(1) := int;
                     read(l, int);
                     rnd_rec.seed(2) := int;
                     read(l, int);
                     rnd_rec.seed(3) := int;
                     Elsif (rnd_lead(i) = rnd_lead(distribution)) then
                           random_dist1(rnd_rec, l);
                    Else

                        If (read_str = rnd_lead(mean)) Then
                            read(l, rnd_rec.mean);
                        Elsif (read_str = rnd_lead(std_dev)) Then
                            read(l, rnd_rec.std_dev);
                        Elsif (read_str = rnd_lead(trials)) Then
                            read(l, rnd_rec.trials);
                        Elsif (read_str = rnd_lead(rnd)) Then
                            read(l, rnd_rec.rnd);
                        Elsif (read_str = rnd_lead(bound_l)) Then
                            read(l, rnd_rec.bound_l);
                        Elsif (read_str = rnd_lead(bound_h)) Then
                            read(l, rnd_rec.bound_h);
                        Elsif (read_str = rnd_lead(p_success)) Then
                            read(l, rnd_rec.p_success);
                        Else
                          Assert False
                             report "Invalid field name found"
                             Severity warning;
                        End If;
                    End if;
                End if;
            End loop;
        End loop;
    End Rnd_Read_Record;
-- -------------------------------------------------------------------------

    Procedure Rnd_Random (rnd_rec: InOut rnd_rec_t; empirical_data:
    In rnd_empirical_vector_t := (0 => (0.0, 0.0), 1 => (1.0, 1.0))) Is
            -- V-Systems Does Not Like Initial Values
            -- := (0 => (0.0, 0.0),1 => (1.0, 1.0))

    Begin

        Case rnd_rec.distribution Is
            When rnd_constant         => rnd_rec.rnd := rnd_rec.mean;
            When rnd_uniform_d        => uniform_d(rnd_rec);
            When rnd_poisson          => poisson(rnd_rec);
            When rnd_binomial         => binomial(rnd_rec);
            When rnd_geometric        => geometric(rnd_rec);
            When rnd_uniform_c        => uniform_c(rnd_rec);
            When rnd_normal           => normal(rnd_rec);
            When rnd_triangular       => triangular(rnd_rec);
            When rnd_hyperexponential => hyperexponential(rnd_rec);
            When rnd_gamma            => gamma(rnd_rec);
            When rnd_erlang           => erlang(rnd_rec);
            When rnd_empirical_d      => empirical_d(rnd_rec, empirical_data);
            When rnd_empirical_c      => empirical_c(rnd_rec, empirical_data);
            When rnd_exponential      => exponential(rnd_rec);
        End Case;
    End Rnd_Random;

End RANDOM;
