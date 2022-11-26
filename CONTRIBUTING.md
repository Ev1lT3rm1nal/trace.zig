# Contributing to trace.zig

Contributions are very welcome to this project. In this document I highlight the ideas where you can contribute.

## Contributions to trace.zig GitLab repository

Currently creation of issues should be allowed for everyone with GitLab access (please let me know if this is not the case). Contribution to the source code via forking and merge request. I will consider adding additional users to the repository. The trace.zig repository is organized in the Zig tracing GitLab group. My plan is to add more projects to this group with repositories that expand or improve the trace.zig experience (see below in the section for contribution ideas what this can mean).

## Contribution ideas

### Use it

The best contributions at the moment are through using the library. Report issues (bug and improvements) and provide feedback.

### Fix and issue

I already collected some improvements or limitations that can be fixed. Fork the repository and try to work on them. Ideally you start interacting with me through the issue comments. State your interest that you want to tackle this issue, ask questions etc..

### Utilities to analyze trace log output

Currently the default trace log output is in CSV format. Further evalaution and analysis could be done on the basis of this output, e.g.:

1. Filter the output for trace point log message
2. Analyzing the filtered output, calculating the time duration of each span etc..
3. Visualizing spans

These utilities could be added to the Zig tracing group in GitLab if desired.

### Custom Writers

Provide an implementation for a writer (i.e. a library that can be called from the `writeTracePoint` function that can be implemented in the `root` file). The default writer just logs all trace point with `std.log`. A custom writer could
write to a file, send the trace points via IPC to another process, use an output peripheral available in an embedded system, use JSON or YAML (you name it) as the trace point format etc.. Such writers could be added to the Zig tracing group in GitLab to expand the trace.zig usage.

## Custom clocks

Currently the default clock uses `std.time.Instant` which works for Posix OSs and Windows (and some more). It will not work in an embedded system without any OS or a non Posix OS. Additionally a different, better, faster more safe way may be required or fun to do to provide a custom timestamp.
Therefore creating a custom clock (which is called from the `tracePointTimestamp` implemented in the `root` file) would also benefit trace.zig. As with custom writers I consider such custom clocks a good fit to host them inside the Zig tracing GitLab group.
