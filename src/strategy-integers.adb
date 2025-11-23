with Ada.Numerics.Discrete_Random;

package body Strategy.Integers is

   package body Signed_Integer_Strat is
      package body Impl is

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
               This.Current := This.Min + (This.Max - This.Min) / 2;

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
               This.Current := This.Min + (This.Max - This.Min) / 2;

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
               This.Min := This.Current + 1;

               if This.Min > This.Max then
                   -- Reset to Max (the last known failure)
                   This.Current := This.Max;
                   return False;
               end if;

               This.Current := This.Min + (This.Max - This.Min) / 2;
               return True;

            else
               -- Negative case.
               -- We were searching in [Min, Max]. Min is failure, Max is 0.
               -- Current Passed.
               -- So failure must be < Current.
               -- So Max becomes Current - 1.

               This.Max := This.Current - 1;

               if This.Max < This.Min then
                  This.Current := This.Min;
                  return False;
               end if;

               This.Current := This.Min + (This.Max - This.Min) / 2;
               return True;
            end if;
         end Complicate;

      end Impl;
   end Signed_Integer_Strat;

end Strategy.Integers;
