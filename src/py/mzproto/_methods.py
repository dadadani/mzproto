from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from . import TestSub1, TestSub2


def test_sub1_sum(self: TestSub1) -> int:
    return self.a + self.b


def test_sub1_sum2(self: TestSub1, c: int) -> int:
    return self.a + self.b + c


def test_sub2_sum(self: TestSub2) -> int:
    return self.a + self.b
