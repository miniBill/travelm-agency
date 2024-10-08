headline = Translation bundles
preamble = Until now, we only considered a single set of translation files for multiple languages.
  In large applications, we might benefit from not loading all translations for a language at once, but instead
  loading just the translations we need for the current page or subtree of pages. This
  feature is only doing something relevant in <code>Dynamic</code> mode, since in <code>Inline</code> mode,
  all translations are in the main Elm bundle regardless.

considerationsHeadline = Considerations
considerationsBody = Make sure you need this feature before using it. It weakens your compile-time guarantees,
  since you need to remember to include the right bundles on the right pages. If a key is not loaded yet, the respective function
  will return an empty string. Right now, Travelm-Agency compiles all of your translation keys into a flat list of exports,
  which does not really help in particular to distinguish the corresponding files where the keys are contained.
  Prefixing your translations might help, which is why you can run travelm-agency with <code>--prefix_file_identifier</code>. This will prefix the bundle name
  to each of the exposed accessor functions, i.e. if you have a translation "headline" in the file "summary.en.ftl", you can access that translation via "summaryHeadline".
  If you benchmarked and found out that bundling improves your render time a lot, let me know. I'm open for pull requests and suggestions
  to improve the generated code.

exploreHeadline = Explore
exploreBody = The editor lets you create new files on this page! Add new bundles and see how the output changes.
