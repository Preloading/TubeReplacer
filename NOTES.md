# random notes

- ML stands for medialib
- the l(@"") function handles proper underscore placement between different versions.
- to find the callstack of a function w/o using a debugger, you can use
```
    intptr_t slide = _dyld_get_image_vmaddr_slide(0);
    NSLog(@"ASLR Slide Offset: 0x%lx\n", (unsigned long)slide);
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **symbols = backtrace_symbols(callstack, frames);
    NSMutableString *callstackString = [NSMutableString stringWithFormat:@"uwu >_<"];
    for (int i = 0; i < frames; i++) {
    [callstackString appendFormat:@"%s\n", symbols[i]];
    }
    NSLog(@"%@", callstackString);
  ```