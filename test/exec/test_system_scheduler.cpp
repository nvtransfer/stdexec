/*
 * Copyright (c) 2023 Lee Howes
 *
 * Licensed under the Apache License Version 2.0 with LLVM Exceptions
 * (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *   https://llvm.org/LICENSE.txt
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <catch2/catch.hpp>
#include <exec/system_scheduler.hpp>

TEST_CASE("simple schedule init", "[types][system_scheduler]") {
  exec::system_context ctx;
  exec::system_scheduler sched = ctx.get_scheduler();
  // TODO
}

TEST_CASE("simple schedule forward progress guarantee", "[types][system_scheduler]") {
  exec::system_context ctx;
  exec::system_scheduler sched = ctx.get_scheduler();
  REQUIRE(stdexec::get_forward_progress_guarantee(sched) == stdexec::forward_progress_guarantee::parallel);
}
