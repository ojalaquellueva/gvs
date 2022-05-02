# Application configuration directory

* Contains passwords and other sensitive parameters
* For final installation, rename from `config_example` to `config` and move this directory and its contents outside application code repository (src/).
* For a secure installation, this directory MUST be located outside application code directory
* Rename configuration files by removing ".example" suffix
* Set parameters as required
* Adjust configuration file paths in src/params.sh & src/params.php accordingly, so that they point to the correct location of this directory