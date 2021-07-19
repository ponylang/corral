## Fixed bug where corral update would result in incorrect code in the corral

When a dependency had a version constraint rather than a single value, the first time `corral update` was run, you wouldn't end up with the correct code checked out. The constraint was correctly solved, but the checked out code would be for branch `main`. 
