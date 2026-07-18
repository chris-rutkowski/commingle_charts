# AI notes

## Running tests

Run tests inside the containerised runner so golden images match CI byte-for-byte:

```bash
scripts/containerised_test.sh
```

## Regenerating goldens

To regenerate the golden images in place:

```bash
scripts/containerised_test.sh --update-goldens
```
