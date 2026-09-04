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
