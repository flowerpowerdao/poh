<script lang="ts">
  import { store } from "../store";
</script>

<div class="fixed top-0 right-0">
  <div class="dropdown dropdown-end">
    <!-- svelte-ignore a11y-label-has-associated-control -->
    <label tabindex="0" class="btn m-1">
      {$store.principal?.toString().slice(0, 5) +
        "…" +
        $store.principal?.toString().slice(-3)}
    </label>
    <ul
      tabindex="0"
      class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52"
    >
      <li
        on:click={async () => await store.disconnect()}
        class="cursor-pointer"
      >
        disconnect wallet
      </li>
    </ul>
  </div>
</div>
