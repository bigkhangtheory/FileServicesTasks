# Technical Summary

The growth of DSC has is still in it's early stages, and may fail in receiving widespread adoption for some time. One of the main reasons is the tooling required to automate the process of building the **DSC artifacts** *(MOF, Meta MOF, Compresses Modules)* and automated testing is not implicitly implemented.

One of the goals of this project is to manage the complexity that comes with DSC. There needs to be proper **tooling** that solves these issues:

---

##### **Configuration Management** must be flexible and scalable.

- **The DSC documentation is technically correct but does not lead people the right way**.
- If one follows [Using configuration data in DSC](https://docs.microsoft.com/en-us/powershell/scripting/dsc/configurations/configData?view=powershell-7) and [Separating configuration and environment data](https://docs.microsoft.com/en-us/powershell/scripting/dsc/configurations/separatingenvdata?view=powershell-7), **the outcome will be unmanageable**, if the **configuration data** gets more complex like dealing with roles, differences between locations and / or environments.
- The solution to this problem is [Datum](https://github.com/gaelcolas/Datum), which is described in detail in the [Exercises](./Exercises).

---

##### **Build Execution** must be portable
- Building the solution and creating the artifacts requires a **Single Build Script**, or as I say, a ***"Single Point of Entry***".
- This gets very difficult if the build process has any manual steps or preparations that needs to be done.
- After you have pushed your changes and want to create new artifacts, running the [Build.ps1 script](./DSC/Build.ps1) is the ***"entry point"*** of execution.
- This build script **runs locally** or **inside a release pipeline**... aka *Gitlab Runners*.

---

##### **Dependency Resolution** must be self-contained
- Self-contained *dependency resolution* makes it possible to move a solution from local build into a CI/CD pipeline.
- However, many DSC solutions require downloading a bunch of dependencies prior being able to run the build.
- This project uses [PSDepend](https://github.com/RamblingCookieMonster/PSDepend/) to download all required resources from either the **PowerShell Gallery** or our **internal repository feed**.

---

##### **Automated Testing**
- Integration and acceptance testing is essential to verify the **integrity of the configuration data**.
- This project uses [Pester](https://pester.dev/) for this. Additionally, the artifacts must be tested in the development as well as the test environment prior deploying them to them to the production environment.
- This process should be fully automated and self-contained as well.

## Technical Details

- Configuration management that allows multiple layers of data *(`*.psd1` files and hash tables can’t be the solution)*
- Tooling to fully automated the build and release process
- Dependency resolution
- Maintenance windows (which the LCM does not implicitly support)
- Reporting (at least if you are using the on-prem pull server)
- Git branching model
- Automated testing
