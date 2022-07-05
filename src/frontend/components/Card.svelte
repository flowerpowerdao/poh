<div class="card bg-base-300 shadow-lg">
  <div class="card-body">
    <div class="card-title">
      <slot name="title" />
    </div>
    <p>
      <slot name="body" />
    </p>
    <div class="card-actions justify-center">
      <slot name="actions" />
    </div>
  </div>
</div>
