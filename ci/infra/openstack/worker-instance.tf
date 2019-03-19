data "template_file" "worker-cloud-init" {
  template = "${file("cloud-init/worker.tpl")}"

  vars {
    authorized_keys = "${join("\n", formatlist("  - %s", var.authorized_keys))}"
  }
}

resource "openstack_blockstorage_volume_v2" "worker_vol" {
  count = "${var.workers_vol_enabled ? "${var.workers}" : 0 }"
  size  = "${var.workers_vol_size}"
  name  = "vol_${element(openstack_compute_instance_v2.worker.*.name, count.index)}"
}

resource "openstack_compute_volume_attach_v2" "worker_vol_attach" {
  count = "${var.workers_vol_enabled ? "${var.workers}" : 0 }"
  instance_id = "${element(openstack_compute_instance_v2.worker.*.id, count.index)}"
  volume_id   = "${element(openstack_blockstorage_volume_v2.worker_vol.*.id, count.index)}"
}

resource "openstack_compute_instance_v2" "worker" {
  count      = "${var.workers}"
  name       = "ag-worker-${var.stack_name}-${count.index}"
  image_name = "${var.image_name}"

  flavor_name = "${var.worker_size}"

  network {
    name = "${var.internal_net}"
  }

  security_groups = [
    "${openstack_compute_secgroup_v2.secgroup_base.name}",
    "${openstack_compute_secgroup_v2.secgroup_worker.name}",
  ]

  user_data = "${data.template_file.worker-cloud-init.rendered}"
}

resource "openstack_networking_floatingip_v2" "worker_ext" {
  count = "${var.workers}"
  pool  = "${var.external_net}"
}

resource "openstack_compute_floatingip_associate_v2" "worker_ext_ip" {
  count       = "${var.workers}"
  floating_ip = "${element(openstack_networking_floatingip_v2.worker_ext.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.worker.*.id, count.index)}"
}
