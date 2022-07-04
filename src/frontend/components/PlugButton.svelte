<script lang="ts">
  import { onMount } from "svelte";
  import { store } from "../store";

  import Button from "./Button.svelte";

  export let loading;
  export let toggleModal;

  onMount(async () => {
    const connected = await window.ic?.plug?.isConnected();
    if (connected) {
      console.log("plug connection detected");
      store.plugConnect();
    }
  });

  async function connect() {
    loading = "plug";
    await store.plugConnect();
    loading = "";
    toggleModal();
  }
</script>

<Button
  on:click={connect}
  disabled={loading}
>
  {#if loading === "plug"}
    loading
  {:else}
    plug
  {/if}
</Button>
