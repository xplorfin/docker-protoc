
set -e

printUsage() {
    echo "protoc-mono is a convenience wrapper for protoc-all geared towards monorepos"
    echo " "
    echo "Usage: protoc-mono -s service1,service2,service3 -g service1 -l go"
    echo " "
    echo "options:"
    echo " -h, --help           Show help"
    echo " -s SERVICES          A comma delimited list of services to generate. Each service should be in a sub-folder"
    echo " -g GATEWAY_SERVICE   An optional single service to generate a grpc-gateway container"
    echo " -l LANGUAGE          The language to generate (${SUPPORTED_LANGUAGES[@]})"
    echo " -o DIRECTORY         The output directory for generated files. Will be automatically created."
    echo " --lint CHECKS        Enable linting protoc-lint (CHECKS are optional - see https://github.com/ckaznocha/protoc-gen-lint#optional-checks)"
    echo " --with-docs FORMAT   Generate documentation (FORMAT is optional - see https://github.com/pseudomuto/protoc-gen-doc#invoking-the-plugin)"
    echo " --go-source-relative Make go import paths 'source_relative' - see https://github.com/golang/protobuf#parameters"
}

GEN_DOCS=false
DOCS_FORMAT="html,index.html"
LINT=false
LINT_CHECKS=""
SUPPORTED_LANGUAGES=("go" "ruby" "csharp" "java" "python" "objc" "gogo" "php" "node" "web" "cpp")
EXTRA_INCLUDES=""
OUT_DIR=""
GO_SOURCE_RELATIVE=""

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            printUsage
            exit 0
            ;;
        -f)
            shift
            if test $# -gt 0; then
                FILE=$1
            else
                echo "no input file specified"
                exit 1
            fi
            shift
            ;;
        -d)
            shift
            if test $# -gt 0; then
                PROTO_DIR=$1
            else
                echo "no directory specified"
                exit 1
            fi
            shift
            ;;
        -l)
            shift
            if test $# -gt 0; then
                GEN_LANG=$1
            else
                echo "no language specified"
                exit 1
            fi
            shift
            ;;
        -o) shift
            OUT_DIR=$1
            shift
            ;;
        -i) shift
            EXTRA_INCLUDES="$EXTRA_INCLUDES -I$1"
            shift
            ;;
        --with-docs)
            GEN_DOCS=true
            if [ "$#" -gt 1 ] && [[ $2 != -* ]]; then
                DOCS_FORMAT=$2
                shift
            fi
            shift
            ;;
        --lint)
            LINT=true
            if [ "$#" -gt 1 ] && [[ $2 != -* ]]; then
                LINT_CHECKS=$2
		        shift
            fi
            shift
            ;;
         --go-source-relative)
            GO_SOURCE_RELATIVE="paths=source_relative,"
            shift
            ;;
        *)
            break
            ;;
    esac
done

if [[ -z $FILE && -z $PROTO_DIR ]]; then
    echo "Error: You must specify a proto file or proto directory"
    printUsage
    exit 1
fi

if [[ ! -z $FILE && ! -z $PROTO_DIR ]]; then
    echo "Error: You may specifiy a proto file or directory but not both"
    printUsage
    exit 1
fi

if [ -z $GEN_LANG ]; then
    echo "Error: You must specify a language: ${SUPPORTED_LANGUAGES[@]}"
    printUsage
    exit 1
fi

if [[ ! ${SUPPORTED_LANGUAGES[*]} =~ "$GEN_LANG" ]]; then
    echo "Language $GEN_LANG is not supported. Please specify one of: ${SUPPORTED_LANGUAGES[@]}"
    exit 1
fi
