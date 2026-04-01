import load_data


def test_build_expected_filenames() -> None:
    assert load_data.build_expected_filenames(["2026-01", "2026-02"]) == [
        "yellow_tripdata_2026-01.parquet",
        "yellow_tripdata_2026-02.parquet",
    ]


def test_extract_available_yellow_filenames_deduplicates_and_sorts() -> None:
    page_html = """
    <a href="https://example.com/yellow_tripdata_2026-02.parquet">Fevrier</a>
    <a href="https://example.com/yellow_tripdata_2026-01.parquet">Janvier</a>
    <a href="https://example.com/yellow_tripdata_2026-02.parquet">Fevrier</a>
    """
    assert load_data.extract_available_yellow_filenames(page_html) == [
        "yellow_tripdata_2026-01.parquet",
        "yellow_tripdata_2026-02.parquet",
    ]


def test_resolve_tlc_download_url_prefers_official_link() -> None:
    page_html = """
    <a href="/assets/yellow_tripdata_2026-02.parquet">
      yellow_tripdata_2026-02.parquet
    </a>
    """
    assert load_data.resolve_tlc_download_url(
        "yellow_tripdata_2026-02.parquet",
        page_html=page_html,
    ) == ("https://www.nyc.gov/assets/yellow_tripdata_2026-02.parquet")


def test_resolve_tlc_download_url_falls_back_when_link_missing(monkeypatch) -> None:
    monkeypatch.setattr(
        load_data, "BASE_URL", "https://downloads.example.com/trip-data"
    )
    assert (
        load_data.resolve_tlc_download_url(
            "yellow_tripdata_2026-02.parquet",
            page_html="<html></html>",
        )
        == "https://downloads.example.com/trip-data/yellow_tripdata_2026-02.parquet"
    )
