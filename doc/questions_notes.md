# Questions / Notes

On Pony and Corral and package dependency mananagement things we could change.

- Local Override: Stable allows local bundles that are just [relative] path entries in the bundle, resulting in canonicalized paths in the PONYPATH. How can we do this while also tracking a remote location to allow local development of a published library? That is: use remote, fork remote and work on local, commit fork to remote and go back to using that. This could be a simple matter of tracking the local location as a temporary override. Or, we just let the developer update (remove+add) the bundle with the alternate locator. Or, use a more general alias technique like go mod?

- Bundle name collision. When Corral copies bundles into the bundle-corral tree, different bundles with the same name would collide. We’ll need to disambiguate these bundle roots.

- Package name collision. Completely different bundles might have packages with the same name, and these will accidentally collide when they are all on the same PONYPATH. This is inherently a ponyc problem, and not a Corral problem. But if ponyc is enhanced to allow bundle scoping of packages, Corral will need to be updated.

- Package version variation. Sometimes different source packages might want to use different versions of the same package which ponyc would allow, but can’t be told how since all the dependencies are listed on the same PONYPATH. Similar to above and would need ponyc enhancement.

- Relative uses. Packages in a bundle should use relative paths to use their sibling packages. This should always result in unambiguous usage of the package from the same version of the same bundle.

- Corralled bundles would have their own corral.json that would supply the bundle details for resolving all the transitive package usages in the bundle project.
   - The PONYPATH could have a form where we provided different roots for different bundles being compiled. For example, compiling bundle alpha that depends on bundles beta and gamma, and each of those in turn depend on a bundle delta that could be the same, or different version, or completely different but with the same package names.
   - alpha/
      - corral.json
      - _corral/
         - alpha/
            - beta/
               - pkg1 (delta is .corral/beta/delta)
               - pkg2 (delta is .corral/beta/delta)
            - gamma/
               - pkg3 (delta is .corral/gamma/delta)
               - pkg4 (delta is .corral/gamma/delta)
        - beta/
            - delta/
                - pkg5
                - pkg6
        - gamma/
            - delta/
                - pkg5’
                - pkg7
    - PONYPATH=...:alpha@~/alpha/_corral/alpha:beta@~/alpha/_corral/beta:gamma@~/alpha/_corral/gamma
        - Qualified paths would include a bundle-name@path.
        - Ponyc would only use this package root path when the bundle being compiled was bundle-name.
        - Ponyc determines the current package’s bundle by walking up the package path until a dir path segment matched one of the bundle-names in the qualified path.
    - An alternative form would be to leave off the bundle-name before the @, and just assume the last segment in the @path was the bundle-name.
        - PONYPATH=...:@~/alpha/_corral/alpha:@~/alpha/_corral/beta:@~/alpha/_corral/gamma
