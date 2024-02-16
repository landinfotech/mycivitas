from django.conf import settings
from django.db import connections
from django.http import Http404, HttpResponse
from rest_framework.views import APIView


class VectorTileAllApi(APIView):
    """Return vector tile."""

    def get(self, request, x: int, y: int, z: int):
        """Return data of features."""
        tile = []

        # Create MVT Geom
        sql = f"""
            WITH mvtgeom AS
            (
                SELECT id, description, label, cof, pof, risk,
                    system_id, system_name, community_id, community_name,
                    region_code, region_name, province_code, province_name,
                    asset_class, asset_identifier, asset_sub_class, type,
                    brand, model, contractor, material, diameter, length, geometry_type, def_stylename,
                    ST_AsMVTGeom(
                        ST_Transform(geom, 3857), ST_TileEnvelope({z}, {x}, {y}),
                        extent => 4096, buffer => 64
                    ) as geom
                    FROM mv_features AS feature
            ) SELECT ST_AsMVT(mvtgeom.*)
            FROM mvtgeom
        """

        # Filters
        filters = []
        communities = request.GET.get('community_ids', None)
        if communities:
            filters.append(f'community_id IN ({communities})')

        # Filter for system
        # TODO:
        #  We need to handle the validation
        #  Should be system_names='Transportation Network','Water Network'
        system_names = request.GET.get('system_names', None)
        if system_names:
            filters.append(f'system_name IN ({system_names})')

        # Append to sql
        if filters:
            sql += ' WHERE ' + ' AND '.join(filters)

        # Raw query it
        with connections[settings.CIVITAS_DATABASE].cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            for row in rows:
                tile.append(bytes(row[0]))

        # If no tile 404
        if not len(tile):
            raise Http404()
        return HttpResponse(tile, content_type="application/x-protobuf")