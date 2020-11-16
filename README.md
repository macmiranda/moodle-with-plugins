# moodle-with-plugins

The idea is to have a small Docker image using Alpine as a base with all php modules enabled (except for the database ones which should be postgres only) and allow for installation of Moodle plugins usin Moosh during build time.

Extra configuration that shall be available as well:

- locale
- timezone
