<script lang="ts">
  import { onMount } from "svelte";
  import { whitelist } from "canisters/whitelist";
  import type { Result } from "canisters/whitelist/whitelist.did";

  async function checkStatus() {
    const res: Result = await whitelist.checkStatus();
  }

  onMount(checkStatus);
</script>
