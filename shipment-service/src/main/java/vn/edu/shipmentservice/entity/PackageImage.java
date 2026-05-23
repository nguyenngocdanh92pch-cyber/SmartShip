package vn.edu.shipmentservice.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "package_images")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PackageImage {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id; // [cite: 117]

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "shipment_id", nullable = false)
    private Shipment shipment; // [cite: 118]

    @Column(name = "image_url", nullable = false)
    private String imageUrl; // [cite: 119]
}
