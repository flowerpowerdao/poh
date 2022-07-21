<script lang="ts">
  import { store } from "../store";
  import Menu from "./Menu.svelte";
  import Login from "./Login.svelte";

  // get random number between 1 and 18
  let randomLogo = Math.floor(Math.random() * 18) + 1;
</script>

<div class="fixed top-0 inset-x-0 z-10 flex justify-between">
  <a href="/#">
    <img
      class="h-auto w-full"
      src={`BP_FPDAO_Logo_BlackOnWhite_sRGB_${randomLogo}.svg`}
      alt="fpdao logo"
    />
  </a>
  {#if $store.isAuthed}
    <Menu />
  {:else}
    <Login />
  {/if}
</div>
