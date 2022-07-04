<script lang="ts">
  export let disabled: boolean = undefined;
  export let style: string = "";
</script>

<button class="{style} btn" on:click {disabled}>
  <slot />
</button>
