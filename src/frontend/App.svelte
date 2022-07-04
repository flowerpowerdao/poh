<script lang="ts">
  import Login from "./components/Login.svelte";
  import { store } from "./store";

  import Menu from "./components/Menu.svelte";

  import CheckPOH from "./pages/CheckPOH.svelte";
  import Error from "./components/Error.svelte";
</script>

<div class="h-screen flex flex-col items-center justify-center">
  {#if $store.isAuthed}
    <Menu />
    <CheckPOH />
  {:else}
    <Login />
  {/if}
</div>
