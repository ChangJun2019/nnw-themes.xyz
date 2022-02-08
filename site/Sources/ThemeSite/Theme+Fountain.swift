import Foundation
import Publish
import Plot

public extension Theme {
    /// A modification of the foundation theme
    static var fountain: Self {
        Theme(
            htmlFactory: FountainHTMLFactory(),
            resourcePaths: ["Resources/website-resources/styles.css"]
        )
    }
}

private struct FountainHTMLFactory<Site: Website>: HTMLFactory {
    func makeIndexHTML(for index: Index,
                       context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: index, on: context.site),
            .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Wrapper {
                    Paragraph(index.body)
                    ItemList(
                        items: context.allItems(
                            sortedBy: \.groupedSorting,
                            order: .ascending
                        ),
                        site: context.site
                    )
                }
                SiteFooter()
            }
        )
    }

    func makeSectionHTML(for section: Section<Site>,
                         context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: section, on: context.site),
            .body {
                SiteHeader(context: context, selectedSelectionID: section.id)
                Wrapper {
                    H1(section.title)
                    ItemList(items: section.items, site: context.site)
                }
                SiteFooter()
            }
        )
    }

    func makeItemHTML(for item: Item<Site>,
                      context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: item, on: context.site),
            .body(
                .class("item-page"),
                .components {
                    SiteHeader(context: context, selectedSelectionID: item.sectionID)
                    Wrapper {
                        makeInnerItem(for: item, in: context.site)
                    }
                    SiteFooter()
                }
            )
        )
    }

    func makePageHTML(for page: Page,
                      context: PublishingContext<Site>) throws -> HTML {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Wrapper(page.body)
                SiteFooter()
            }
        )
    }

    func makeTagListHTML(for page: TagListPage,
                         context: PublishingContext<Site>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Wrapper {
                    H1("Browse all tags")
                    List(page.tags.sorted()) { tag in
                        ListItem {
                            Link(tag.string,
                                 url: context.site.path(for: tag).absoluteString
                            )
                            .class("tag-\(tag.string.replacingOccurrences(of: " ", with: "-").lowercased())")
                        }
                        .class("tag")
                    }
                    .class("all-tags")
                }
                SiteFooter()
            }
        )
    }

    func makeTagDetailsHTML(for page: TagDetailsPage,
                            context: PublishingContext<Site>) throws -> HTML? {
        HTML(
            .lang(context.site.language),
            .head(for: page, on: context.site),
            .body {
                SiteHeader(context: context, selectedSelectionID: nil)
                Wrapper {
                    H1 {
                        Text("Tagged with ")
                        Span(page.tag.string)
                            .class("tag")
                            .class("tag-\(page.tag.string.replacingOccurrences(of: " ", with: "-").lowercased())")
                    }

                    Link("Browse all tags",
                        url: context.site.tagListPath.absoluteString
                    )
                    .class("browse-all")

                    ItemList(
                        items: context.items(
                            taggedWith: page.tag,
                            sortedBy: \.groupedSorting,
                            order: .ascending
                        ),
                        site: context.site
                    )
                }
                SiteFooter()
            }
        )
    }
}

private struct Wrapper: ComponentContainer {
    @ComponentBuilder var content: ContentProvider

    var body: Component {
        Div(content: content).class("wrapper")
    }
}

private struct SiteHeader<Site: Website>: Component {
    var context: PublishingContext<Site>
    var selectedSelectionID: Site.SectionID?

    var body: Component {
        Header {
            Wrapper {
                Link(context.site.name, url: "/")
                    .class("site-name")

                if Site.SectionID.allCases.count > 1 {
                    navigation
                }
            }
        }
    }

    private var navigation: Component {
        Navigation {
            List(Site.SectionID.allCases) { sectionID in
                let section = context.sections[sectionID]

                return Link(section.title,
                    url: section.path.absoluteString
                )
                .class(sectionID == selectedSelectionID ? "selected" : "")
            }
        }
    }
}

private struct ItemList<Site: Website>: Component {
    var items: [Item<Site>]
    var site: Site

    var body: Component {
        List(items) { item in
            makeInnerItem(for: item, in: site)
        }
        .class("item-list")
    }
}


func makeInnerItem<Site: Website>(for item: Item<Site>, in site: Site) -> Component {
    return Article {
        Link(url: (item as? Item<ThemeSite>)?.metadata.themelink ?? "") { Image(url: "/add-icon.png", description: "Install Theme to NetNewsWire").class("install-button") }
        H1(item.title).style("display: inline;")
        Span(" • \((item as? Item<ThemeSite>)?.metadata.creator ?? "")").class("creator")
        ItemTagList(item: item, site: site)
        Div(item.content.body).class("content")
    }
}

private struct ItemTagList<Site: Website>: Component {
    var item: Item<Site>
    var site: Site

    var body: Component {
        List(item.tags) { tag in
            Link(tag.string, url: site.path(for: tag).absoluteString)
            .class("tag-\(tag.string.replacingOccurrences(of: " ", with: "-").lowercased())")
        }
        .class("tag-list")
    }
}

private struct SiteFooter: Component {
    var body: Component {
        Footer {
            Paragraph {
                Span {
                    Text("Generated by abusing ")
                    Link("Publish", url: "https://github.com/johnsundell/publish")
                }
            }
            Paragraph {
                Span {
                    Link("RSS feed", url: "/feed.rss")
                }
                Text(" • ")
                Span {
                    Link("License", url: "/license")
                }
            }
        }
    }
}

extension Item {
    var groupedSorting: String {
        return "\(tags.contains("User Theme") ? 0 : 1) \(title)"
    }
}