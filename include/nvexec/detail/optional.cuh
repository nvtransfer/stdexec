/*
 * Copyright (c) 2022 NVIDIA Corporation
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
#pragma once

#include <new>
#include <utility>
#include "config.cuh"

#include "../../stdexec/concepts.hpp"

namespace nvexec {

  struct nullopt_t { };

  inline constexpr nullopt_t nullopt{};

  struct bad_optional_access : std::exception {
    bad_optional_access() = default;
    bad_optional_access(const bad_optional_access&) = default;
    bad_optional_access& operator=(const bad_optional_access&) = default;

    virtual const char* what() const noexcept {
      return "bad_optional_access";
    }
  };

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // optional<T>
  template <class T>
  struct optional {
    optional(nullopt_t = {}) noexcept
      : has_value_(false) {
    }

    optional(optional&& other) noexcept(stdexec::__nothrow_constructible_from<T, T>)
      requires stdexec::constructible_from<T, T>
      : has_value_(other.has_value_) {
      if (has_value_) {
        ::new (&value_) T(std::move(other.value_));
      }
    }

    optional(const optional& other)
      requires stdexec::constructible_from<T, const T&>
      : has_value_(other.has_value_) {
      if (has_value_) {
        ::new (&value_) T(other.value_);
      }
    }

    template <class... As>
      requires stdexec::constructible_from<T, As...>
    explicit optional(std::in_place_t, As&&... as)
      : has_value_(true) {
      ::new (&value_) T((As&&) as...);
    }

    template <class U = T>
      requires stdexec::constructible_from<T, U>
            && (stdexec::__none_of<stdexec::__decay_t<U>, std::in_place_t, optional<T>>)
            && (!stdexec::same_as<const T, const bool>
                || !stdexec::__is_instance_of<stdexec::__decay_t<U>, nvexec::optional>)
    explicit(!stdexec::convertible_to<U&&, T>) optional(U&& value)
      : has_value_(true) {
      ::new (&value_) T((U&&) value);
    }

    optional& operator=(optional&& other) noexcept(
      stdexec::__nothrow_constructible_from<T, T>&& stdexec::__nothrow_assignable_from<T, T>) {
      if (other.has_value()) {
        if (has_value_) {
          value_ = (T&&) *other;
        } else {
          ::new (&value_) T((T&&) *other);
          has_value_ = true;
        }
      } else {
        reset();
      }
      return *this;
    }

    optional& operator=(const optional& other)
      requires stdexec::constructible_from<T, const T&> && stdexec::assignable_from<T, const T&>
    {
      if (other.has_value()) {
        if (has_value_) {
          value_ = *other;
        } else {
          ::new (&value_) T(*other);
          has_value_ = true;
        }
      } else {
        reset();
      }
      return *this;
    }

    ~optional() {
      reset();
    }

    template <class... As>
      requires stdexec::constructible_from<T, As...>
    T& emplace(As&&... as) {
      reset();
      ::new (&value_) T((As&&) as...);
      has_value_ = true;
    }

    void reset() {
      if (has_value_) {
        has_value_ = false;
        value_.~T();
      }
    }

    explicit operator bool() const noexcept {
      return has_value_;
    }

    bool has_value() const noexcept {
      return has_value_;
    }

    T& value() & {
      if (!has_value_)
        throw std::bad_optional_access();
      return value_;
    }

    T&& value() && {
      if (!has_value_)
        throw std::bad_optional_access();
      return (T&&) value_;
    }

    const T& value() const & {
      if (!has_value_)
        throw std::bad_optional_access();
      return value_;
    }

    T& operator*() & noexcept {
      return value_;
    }

    T&& operator*() && noexcept {
      return (T&&) value_;
    }

    const T& operator*() const & noexcept {
      return value_;
    }

    T* operator->() noexcept {
      return &value_;
    }

    const T* operator->() const noexcept {
      return &value_;
    }

   private:
    bool has_value_;

    union {
      T value_;
    };
  };

  //////////////////////////////////////////////////////////////////////////////////////////////////
  // optional<T> specialization for trivially copyable types
  template <class T>
    requires(std::is_trivially_copyable_v<T>)
  struct optional<T> {
    optional(nullopt_t = {}) noexcept
      : has_value_(false) {
    }

    optional(optional&& other) noexcept = default;
    optional(const optional& other) noexcept = default;
    optional& operator=(optional&& other) noexcept = default;
    optional& operator=(const optional& other) noexcept = default;

    template <class... As>
      requires stdexec::constructible_from<T, As...>
    explicit optional(std::in_place_t, As&&... as)
      : has_value_(true) {
      ::new (&value_) T((As&&) as...);
    }

    template <class U = T>
      requires stdexec::constructible_from<T, U>
            && (stdexec::__none_of<stdexec::__decay_t<U>, std::in_place_t, optional<T>>)
            && (!stdexec::same_as<const T, const bool>
                || !stdexec::__is_instance_of<stdexec::__decay_t<U>, nvexec::optional>)
    explicit(!stdexec::convertible_to<U&&, T>) optional(U&& value)
      : has_value_(true) {
      ::new (&value_) T((U&&) value);
    }

    template <class... As>
      requires stdexec::constructible_from<T, As...>
    T& emplace(As&&... as) {
      reset();
      ::new (&value_) T((As&&) as...);
      has_value_ = true;
    }

    void reset() {
      has_value_ = false;
    }

    explicit operator bool() const noexcept {
      return has_value_;
    }

    bool has_value() const noexcept {
      return has_value_;
    }

    T& value() & {
      if (!has_value_)
        throw std::bad_optional_access();
      return value_;
    }

    T&& value() && {
      if (!has_value_)
        throw std::bad_optional_access();
      return (T&&) value_;
    }

    const T& value() const & {
      if (!has_value_)
        throw std::bad_optional_access();
      return value_;
    }

    T& operator*() & noexcept {
      return value_;
    }

    T&& operator*() && noexcept {
      return (T&&) value_;
    }

    const T& operator*() const & noexcept {
      return value_;
    }

    T* operator->() noexcept {
      return &value_;
    }

    const T* operator->() const noexcept {
      return &value_;
    }

   private:
    bool has_value_;

    union {
      T value_;
    };
  };

  static_assert(std::is_trivially_copyable_v<optional<int>>);

}
