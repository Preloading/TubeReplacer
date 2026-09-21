// So I tried to do this on device..... 2.4MBs of JS parsing takes 40 seconds and eats literally all the ram sooooo I don't think this is happening on device....


#import "jsanalyzer.h"
#include "lib/include/tree_sitter/api.h"

const TSLanguage *tree_sitter_javascript(void);

@implementation TRJSAnalyzer

-(void)parseScript:(NSData*)jsCode {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    TSParser *parser = ts_parser_new();

    // Set the parser's language (JSON in this case).
    ts_parser_set_language(parser, tree_sitter_javascript());
    NSLog(@"parsing 1");
    NSDate *startDate = [NSDate date];


    // Build a syntax tree based on source code stored in a string.
    const char *source_code = jsCode.bytes;

    TSTree *tree = ts_parser_parse_string(
        parser,
        NULL,
        source_code,
        (uint32_t)jsCode.length
    );

        NSLog(@"parsing 2");

    NSLog(@"parsing time taken: %f", [startDate timeIntervalSinceNow]);

    // Get the root node of the syntax tree.
    TSNode root = ts_tree_root_node(tree);

    TSQueryCursor *cursor = ts_query_cursor_new();

    const char *queryString =
        "(variable_declarator\n"
        "  name: (identifier) @name\n"
        "  value: (function\n"
        "    parameters: (formal_parameters) @params\n"
        "    body: (statement_block) @body))";

    uint32_t error_offset;
    TSQueryError error_type;
    NSLog(@"parsing 3");
    TSQuery *query = ts_query_new(
        tree_sitter_javascript(),
        queryString,
        strlen(queryString),
        &error_offset,
        &error_type
    );

    if (!query) {
        fprintf(stderr, "Query error at byte %u\n", error_offset);
    }
    NSLog(@"parsing 4");
    ts_query_cursor_exec(cursor, query, root);

    TSQueryMatch match;
    NSLog(@"parsing 5");

    uint32_t count = 0;

    while (ts_query_cursor_next_match(cursor, &match)) {
        count++;

        NSLog(@"match %u", count);

        if (count > 1000) {
            break;
        }
    }
        // NSLog(@"root function");
        // TSNode body = ...;
        // TSNode params = ...;
        
        // if (ts_node_named_child_count(params) < 3)
        //     continue;

        // inspect body...
    // }

    NSLog(@"parsing 6");
    // Get some child nodes.
    // TSNode array_node = ts_node_named_child(root_node, 0);
    // TSNode number_node = ts_node_named_child(array_node, 0);
    //     NSLog(@"parsing 3");


    // Check that the nodes have the expected types.
    // assert(strcmp(ts_node_type(root_node), "document") == 0);
    // assert(strcmp(ts_node_type(array_node), "array") == 0);
    // assert(strcmp(ts_node_type(number_node), "number") == 0);

    //     NSLog(@"parsing 4");


    // // Check that the nodes have the expected child counts.
    // assert(ts_node_child_count(root_node) == 1);
    // assert(ts_node_child_count(array_node) == 5);
    // assert(ts_node_named_child_count(array_node) == 2);
    // assert(ts_node_child_count(number_node) == 0);

    // Print the syntax tree as an S-expression.
    // char *string = ts_node_string(root_node);
    // NSLog(@"Syntax tree: %s\n", string);

    // Free all of the heap-allocated memory.
    // free(string);
    ts_tree_delete(tree);
    ts_parser_delete(parser);
    [pool release];
    return;
}
@end