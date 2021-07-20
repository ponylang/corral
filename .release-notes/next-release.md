## Fix bug that prevented lock.json from being populated

After resolving version constraints, the correct revision was being determined but wasn't written to the lock.json file.

