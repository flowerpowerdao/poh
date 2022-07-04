<script>
  import { onMount } from "svelte";
  import { StoicIdentity } from "ic-stoic-identity";
  import { store } from "../store";

  import Button from "./Button.svelte";

  export let loading;
  export let toggleModal;

  onMount(async () => {
    StoicIdentity.load().then(async (identity) => {
      if (identity !== false) {
        //ID is a already connected wallet!
        store.stoicConnect();
      }
    });
  });

  async function connect() {
    loading = "stoic";
    await store.stoicConnect();
    loading = "";
    toggleModal();
  }
</script>

<Button
  on:click={connect}
  disabled={loading}
>
  {#if loading === "stoic"}
    loading
  {:else}
    stoic
  {/if}
</Button>
