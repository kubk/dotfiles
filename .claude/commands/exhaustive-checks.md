When writing switch statements on discriminated unions, enums, or string literal types, always add an exhaustive check in the default case using `satisfies never`:

```typescript
default:
  return value satisfies never;
```

This ensures TypeScript produces a compile-time error if any case is unhandled. Always use the specific union/enum type for the parameter — never `string`.
