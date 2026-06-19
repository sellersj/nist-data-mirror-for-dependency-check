# nist-data-mirror-for-dependency-check

If the nist api data feeds are struggling or have a huge data import, the script can be
run that will import files from a repo on github.

The files aren't compressed or named how [dependency-check](https://github.com/dependency-check/DependencyCheck)
wants them so this does that conversion. Then it calls the maven plugin for dependency check to import it.
