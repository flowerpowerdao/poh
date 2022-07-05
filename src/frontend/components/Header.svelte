<script lang="ts">
  import { store } from "../store";
  import Menu from "./Menu.svelte";
  import Login from "./Login.svelte";
</script>

<div class="fixed top-0 right-0 z-10">
  {#if $store.isAuthed}
    <Menu />
  {:else}
    <Login />
  {/if}
</div>
