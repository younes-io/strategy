with Ada.Numerics.Discrete_Random;

package body Strategy.Integers is

   package body Signed_Integer_Strat is
      package body Impl is

         --  Compute midpoint of [Min, Max] using a wider intermediate type to avoid overflow.
         function Safe_Midpoint (Min, Max : Value) return Value is
            Min_LL : constant Long_Long_Integer := Long_Long_Integer (Min);
            Max_LL : constant Long_Long_Integer := Long_Long_Integer (Max);
            Mid_LL : constant Long_Long_Integer := Min_LL + (Max_LL - Min_LL) / 2;
         begin
            return Value (Mid_LL);
         end Safe_Midpoint;

         ------------
         -- Create --
         ------------

         function Create (Ctx : in out Runner_Context'Class) return Node is
            package RNG is new Ada.Numerics.Discrete_Random (Value);
            Gen    : RNG.Generator;
            Result : Node;
         begin
            RNG.Reset (Gen, Ctx.Random_Initiator);
            Result.Current := RNG.Random (Gen, First, Last);
            Result.Max     := Last;
            Result.Min     := First;
            return Result;
         end Create;

         -------------
         -- Current --
         -------------

         overriding function Current (This : in out Node) return Value is
         begin
            return This.Current;
         end Current;

         --------------
         -- Simplify --
         --------------

         overriding function Simplify (This : in out Node) return Boolean is
         begin
            --  This shrinking strategy attempts to find the smallest absolute value that fails.
            --  It uses binary search towards 0.

            if This.Current = 0 then
                return False;
            end if;

            if This.Current > 0 then
               -- Current is a failure. It becomes the new Max (upper bound).
               This.Max := This.Current;

               -- If Min (lower bound) is negative, bring it to 0 as we focus on positive range.
               if This.Min < 0 then
                  This.Min := 0;
               end if;

               -- Pick midpoint
               This.Current := Safe_Midpoint (This.Min, This.Max);

               -- If we picked same value, we are done
               if This.Current = This.Max then
                  return False;
               end if;
               return True;

            elsif This.Current < 0 then
               -- Current is a failure. It becomes the new Min (lower bound, closest to negative infinity).
               This.Min := This.Current;

               -- If Max is positive, bring it to 0.
               if This.Max > 0 then
                  This.Max := 0;
               end if;

               -- Pick midpoint.
               This.Current := Safe_Midpoint (This.Min, This.Max);

               if This.Current = This.Min then
                   return False;
               end if;
               return True;
            else
               return False;
            end if;
         end Simplify;

         ----------------
         -- Complicate --
         ----------------

         overriding function Complicate (This : in out Node) return Boolean is
         begin
            -- Complicate is called when Current PASSED.
            -- We want to move back towards the known failure (Max for positives, Min for negatives).

            if This.Current >= 0 then
               -- We were searching in [Min, Max].
               -- Current Passed. So the failure must be > Current.
               -- So Min becomes Current + 1.
               if This.Current = Value'Last then
                  --  Saturate at the bound to avoid overflow.
                  This.Min := This.Current;
               else
                  This.Min := This.Current + 1;
               end if;

               if This.Min > This.Max then
                   -- Reset to Max (the last known failure)
                   This.Current := This.Max;
                   return False;
               end if;

               This.Current := Safe_Midpoint (This.Min, This.Max);
               return True;

            else
               -- Negative case.
               -- We were searching in [Min, Max]. Min is failure, Max is 0.
               -- Current Passed.
               -- So failure must be < Current.
               -- So Max becomes Current - 1.

               if This.Current = Value'First then
                  This.Max := This.Current;
               else
                  This.Max := This.Current - 1;
               end if;

               if This.Max < This.Min then
                  This.Current := This.Min;
                  return False;
               end if;

               This.Current := Safe_Midpoint (This.Min, This.Max);
               return True;
            end if;
         end Complicate;

      end Impl;
   end Signed_Integer_Strat;

end Strategy.Integers;
