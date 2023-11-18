include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(cppbestpractices_template_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(cppbestpractices_template_setup_options)
  option(cppbestpractices_template_ENABLE_HARDENING "Enable hardening" ON)
  option(cppbestpractices_template_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    cppbestpractices_template_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    cppbestpractices_template_ENABLE_HARDENING
    OFF)

  cppbestpractices_template_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR cppbestpractices_template_PACKAGING_MAINTAINER_MODE)
    option(cppbestpractices_template_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(cppbestpractices_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(cppbestpractices_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(cppbestpractices_template_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(cppbestpractices_template_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(cppbestpractices_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(cppbestpractices_template_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(cppbestpractices_template_ENABLE_IPO "Enable IPO/LTO" ON)
    option(cppbestpractices_template_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(cppbestpractices_template_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(cppbestpractices_template_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(cppbestpractices_template_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(cppbestpractices_template_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(cppbestpractices_template_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(cppbestpractices_template_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(cppbestpractices_template_ENABLE_PCH "Enable precompiled headers" OFF)
    option(cppbestpractices_template_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      cppbestpractices_template_ENABLE_IPO
      cppbestpractices_template_WARNINGS_AS_ERRORS
      cppbestpractices_template_ENABLE_USER_LINKER
      cppbestpractices_template_ENABLE_SANITIZER_ADDRESS
      cppbestpractices_template_ENABLE_SANITIZER_LEAK
      cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED
      cppbestpractices_template_ENABLE_SANITIZER_THREAD
      cppbestpractices_template_ENABLE_SANITIZER_MEMORY
      cppbestpractices_template_ENABLE_UNITY_BUILD
      cppbestpractices_template_ENABLE_CLANG_TIDY
      cppbestpractices_template_ENABLE_CPPCHECK
      cppbestpractices_template_ENABLE_COVERAGE
      cppbestpractices_template_ENABLE_PCH
      cppbestpractices_template_ENABLE_CACHE)
  endif()

  cppbestpractices_template_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (cppbestpractices_template_ENABLE_SANITIZER_ADDRESS OR cppbestpractices_template_ENABLE_SANITIZER_THREAD OR cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(cppbestpractices_template_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(cppbestpractices_template_global_options)
  if(cppbestpractices_template_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    cppbestpractices_template_enable_ipo()
  endif()

  cppbestpractices_template_supports_sanitizers()

  if(cppbestpractices_template_ENABLE_HARDENING AND cppbestpractices_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED
       OR cppbestpractices_template_ENABLE_SANITIZER_ADDRESS
       OR cppbestpractices_template_ENABLE_SANITIZER_THREAD
       OR cppbestpractices_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${cppbestpractices_template_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED}")
    cppbestpractices_template_enable_hardening(cppbestpractices_template_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(cppbestpractices_template_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(cppbestpractices_template_warnings INTERFACE)
  add_library(cppbestpractices_template_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  cppbestpractices_template_set_project_warnings(
    cppbestpractices_template_warnings
    ${cppbestpractices_template_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(cppbestpractices_template_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(cppbestpractices_template_options)
  endif()

  include(cmake/Sanitizers.cmake)
  cppbestpractices_template_enable_sanitizers(
    cppbestpractices_template_options
    ${cppbestpractices_template_ENABLE_SANITIZER_ADDRESS}
    ${cppbestpractices_template_ENABLE_SANITIZER_LEAK}
    ${cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED}
    ${cppbestpractices_template_ENABLE_SANITIZER_THREAD}
    ${cppbestpractices_template_ENABLE_SANITIZER_MEMORY})

  set_target_properties(cppbestpractices_template_options PROPERTIES UNITY_BUILD ${cppbestpractices_template_ENABLE_UNITY_BUILD})

  if(cppbestpractices_template_ENABLE_PCH)
    target_precompile_headers(
      cppbestpractices_template_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(cppbestpractices_template_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    cppbestpractices_template_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(cppbestpractices_template_ENABLE_CLANG_TIDY)
    cppbestpractices_template_enable_clang_tidy(cppbestpractices_template_options ${cppbestpractices_template_WARNINGS_AS_ERRORS})
  endif()

  if(cppbestpractices_template_ENABLE_CPPCHECK)
    cppbestpractices_template_enable_cppcheck(${cppbestpractices_template_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(cppbestpractices_template_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    cppbestpractices_template_enable_coverage(cppbestpractices_template_options)
  endif()

  if(cppbestpractices_template_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(cppbestpractices_template_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(cppbestpractices_template_ENABLE_HARDENING AND NOT cppbestpractices_template_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR cppbestpractices_template_ENABLE_SANITIZER_UNDEFINED
       OR cppbestpractices_template_ENABLE_SANITIZER_ADDRESS
       OR cppbestpractices_template_ENABLE_SANITIZER_THREAD
       OR cppbestpractices_template_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    cppbestpractices_template_enable_hardening(cppbestpractices_template_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
