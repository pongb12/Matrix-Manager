cmake_minimum_required(VERSION 3.16)

find_package(Qt6 6.2 REQUIRED COMPONENTS Test)

enable_testing()

add_executable(tst_sizeutils tst_sizeutils.cpp)
target_link_libraries(tst_sizeutils PRIVATE matrix_core Qt6::Test)
add_test(NAME tst_sizeutils COMMAND tst_sizeutils)

add_executable(tst_packageparser tst_packageparser.cpp)
target_link_libraries(tst_packageparser PRIVATE matrix_core Qt6::Test)
add_test(NAME tst_packageparser COMMAND tst_packageparser)

add_executable(tst_cleanuprules tst_cleanuprules.cpp)
target_link_libraries(tst_cleanuprules PRIVATE matrix_core Qt6::Test)
add_test(NAME tst_cleanuprules COMMAND tst_cleanuprules)

add_executable(tst_duplicatescanner tst_duplicatescanner.cpp)
target_link_libraries(tst_duplicatescanner PRIVATE matrix_core Qt6::Test)
add_test(NAME tst_duplicatescanner COMMAND tst_duplicatescanner)

add_executable(tst_filesearcher tst_filesearcher.cpp)
target_link_libraries(tst_filesearcher PRIVATE matrix_core Qt6::Test)
add_test(NAME tst_filesearcher COMMAND tst_filesearcher)

add_executable(tst_asyncprocess tst_asyncprocess.cpp)
target_link_libraries(tst_asyncprocess PRIVATE matrix_core Qt6::Test)
add_test(NAME tst_asyncprocess COMMAND tst_asyncprocess)
