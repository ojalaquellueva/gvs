# Application configuration directory

* Contains passwords and other sensitive information, as well as instance-specific parameters such as base paths. 
* For final installation, rename from `config_example` to `config` and move this directory and its contents to the parent directory of the application code directory `src/`.
* For a secure installation, this directory MUST be located outside application code directory; this is because the application directory is also the repository root directory and therefore public.
* Rename configuration files by removing ".example" suffix
* Set parameters as required
* Adjust configuration file paths in src/params.sh & src/params.php accordingly, so that they point to the correct location of this directory
* Landing page index.html is included in case it contains instance-specific text you wish to preserve(e.g., "GVS Production API", "GVS Development API") and do not want replaced by contents of remote repo.