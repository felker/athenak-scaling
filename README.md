# athenak-scaling
Testing AthenaK scaling on ALCF Polaris

Run `ln -s -f ../../.githooks/pre-commit .git/hooks/pre-commit` (yes, `../../` is the correct relative path even when `ln` is run from top-level repository directory, since it is relative to `.git/hooks/`) in the main directory of the repository to install a hook that clears Jupyter notebook outputs before committing changes.
