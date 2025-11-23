pragma Ada_2022;

with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;

with Strategy; use Strategy;
with Strategy.Standard; use Strategy.Standard;
with Strategy.Runners; use Strategy.Runners;

procedure Strategy_Tests.Standard_Strategies is
   -- This test verifies the standard strategies for Character, String, and Integer.

   function Always_True_String (S : String) return Boolean is (True);
   function Always_True_Char (C : Character) return Boolean is (True);
   function Always_True_Int (I : Integer) return Boolean is (True);

   -- Test instantiation
   package String_Runner is new Runners.Indefinite_Runner (String_Strat.Strat, Test => Always_True_String);
   package Char_Runner is new Runners.Definite_Runner (Character_Strat.Strat, Test => Always_True_Char);
   package Int_Runner is new Runners.Definite_Runner (Integer_Strat.Strat, Test => Always_True_Int);

   -- Test Integer Shrinking
   function Test_Int_Shrink (I : Integer) return Boolean is
   begin
      -- Fail if I > 10. Should shrink to 11.
      -- Wait, if I > 10 is failure condition.
      -- If generated is 100. Fail.
      -- Shrink to 0...100.
      -- 10 passes. 50 fails.
      -- Smallest failure is 11.
      return I <= 10;
   end Test_Int_Shrink;

   package Int_Shrink_Runner is new Runners.Definite_Runner (Integer_Strat.Strat, Test_Int_Shrink);

   Result : Int_Shrink_Runner.Run_Result;

   -- Test Character Shrinking
   function Test_Char_Shrink (C : Character) return Boolean is
   begin
       -- Fail if C > 'a'. Should shrink to 'b'.
       return C <= 'a';
   end Test_Char_Shrink;

   package Char_Shrink_Runner is new Runners.Definite_Runner (Character_Strat.Strat, Test_Char_Shrink);
   Char_Result : Char_Shrink_Runner.Run_Result;

begin
   -- Run Integer Shrink Test
   -- We need to ensure we get a failure. The default range includes large numbers.
   -- We run enough times to likely hit > 10.
   Result := Int_Shrink_Runner.Run (Runs => 1000);
   if Result.Outcome = Fail then
      -- Expect 11
      if Result.Input /= 11 then
         -- It might be acceptable if it didn't find the PERFECT shrink if the iteration limit was hit,
         -- but for integer binary search it should be fast.
         -- However, my shrink implementation:
         -- If 10 passes. 11 fails.
         -- If 12 failed. Mid = (10+12)/2 = 11. 11 Fails.
         -- Max=11. Min=10. Mid=10. 10 Passes.
         -- Min=11. Max=11.
         -- Return False.
         -- So it should stabilize at 11.
         Assert (Result.Input = 11, "Integer should shrink to 11, got " & Integer'Image (Result.Input));
      end if;
   end if;

   -- Run Character Shrink Test
   Char_Result := Char_Shrink_Runner.Run (Runs => 1000);
   if Char_Result.Outcome = Fail then
       -- Expect 'b' (Succ('a'))
       Assert (Char_Result.Input = 'b', "Character should shrink to 'b', got " & Character'Image (Char_Result.Input));
   end if;

   Put_Line ("All standard strategy tests passed.");

end Strategy_Tests.Standard_Strategies;
